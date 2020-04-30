# Resilient Decoding

![](https://github.com/airbnb/ResilientDecoding/workflows/Build/badge.svg) 
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/ResilientDecoding.svg)](https://cocoapods.org/pods/ResilientDecoding)
[![License](https://img.shields.io/cocoapods/l/ResilientDecoding.svg)](https://cocoapods.org/pods/ResilientDecoding)
[![Platform](https://img.shields.io/badge/platform-watchos%20%7C%20ios%20%7C%20tvos%20%7C%20macos%20%7C%20linux-lightgrey.svg?style=flat)](https://cocoapods.org/pods/ResilientDecoding)

## Introduction

This package defines mechanisms to partially recover from errors when decoding `Decodable` types. It also aims to provide an ergonomic API for inspecting decoding errors during development and reporting them in production.

More details follow, but here is a glimpse of what this package enables:
```swift
struct Foo: Decodable {
  @Resilient var array: [Int]
  @Resilient var value: Int?
}
let foo = try JSONDecoder().decode(Foo.self, from: """
  {
    "array": [1, "2", 3],
    "value": "invalid",
  }
  """.data(using: .utf8)!)
```
After running this code, `foo` will be a `Foo` where `foo.array == [1, 3]` and `foo.value == nil`. Additionally, `foo.$array.results` will be `[.success(1), .failure(DecodingError.dataCorrupted(…), .success(3)]` and `foo.$value.error` will be `DecodingError.dataCorrupted(…)`.

## Setup

### Swift Package Manager

In your Package.swift:
```swift
  dependencies: [
    .package(name: "ResilientDecoding", url: "https://github.com/airbnb/ResilientDecoding.git", from: "1.0.0"),
  ]
```

### CocoaPods

In your `Podfile`:

```
platform :ios, '12.0'
pod 'ResilientDecoding', '~> 1.0'
```

## Decoding

The main interface to this package is the `@Resilient` property wrapper. It can be applied to four kinds of properties: `Optional`,  `Array`,  `Dictionary`, and custom types conforming to the `ResilientRawRepresentable` protocol that this package provides. 

### `Optional`

Optionals are the simplest type of property that can be made `Resilient`. A property written as `@Resilient var foo: Int?` will be initialized as `nil` and not throw an error if one is encountered during decoding (for instance, if the value for the `foo` key was a `String`).

### `Array`

`Resilient` can also be applied to an array or an optional array (`[T]?`). A property written as `@Resilient var foo: [Int]` will be initialized with an empty array if the `foo` key is missing or if the value is something unexpected, like `String`. Likewise, if any _element_ of this array fails to decode, that element will be omitted. The optional array variant of this will set the value to `nil` if the key is missing or has a null value, and an empty array otherwise.

### `Dictionary`

`Resilient` can also be applied to a (string-keyed) dictionary or an optional dictionary (`[String: T]?`). A property written as `@Resilient var foo: [String: Int]` will be initialized with an empty dictionary if the `foo` key is missing or if the value is something unexpected, like `String`. Likewise, if any _value_ in the dictionary fails to decode, that value will be omitted. The optional dictionary variant of this will set the value to `nil` if the key is missing or has a null value, and an empty array otherwise.

### `ResilientRawRepresentable`

Custom types can conform to the `ResilientRawRepresentable` protocol which allows them to customize their behavior **when being decoded as a `Resilient` property** (it has no affect otherwise).  `ResilientRawRepresentable` inherits from `RawRepresentable` and is meant to be conformed to primarily by `enum`s with a raw value. `ResilientRawRepresentable` has two static properties: `decodingFallback` and  `isFrozen`.

#### `decodingFallback`
A `ResilientRawRepresentable` type can optionally define a `decodingFallback`, which allows it to be resiliently decoded without being wrapped in an optional. For instance, the following enum can be used in a property written `@Resilient var myEnum: MyEnum`:
```swift
enum MyEnum: String, ResilientRawRepresentable {
  case existing
  case unknown
  static var decodingFallback: Self { .unknown }
}
```

**Note:** `Array`s and `Dictionary`s of `ResilientRawRepresentable`s _always_ omit elements instead of using the `decodingFallback`.

#### `isFrozen`
`isFrozen` controls whether new `RawValues` will report errors to `ResilientDecodingErrorReporter`. By default, `isFrozen` is `false`, which means that a `RawValue` for which `init(rawValue:)` returns `nil` will _not_ report an error. This is useful when you want older versions of your code to support new `enum` cases without reporting errors, for instance when evolving a backend API used by an iOS application. In this way, the property is analogous to Swift's `@frozen` attribute, though they achieve different goals. `isFrozen` has no effect on property-level errors.

## Inspecting Errors

`Resilient` provides two mechanisms for inspecting errors, one designed for use during development and another designed for reporting unexpected errors in production.

### Property-Level Errors

In `DEBUG` builds, `Resilient` properties provide a `projectedValue` with information about errors encountered during decoding. This information can be inspected using the `$property.outcome` property, which is an enum with cases including `keyNotFound` and `valueWasNil`. This is different from errors since the aformentioned two cases are actually not errors when the property value is `Optional`, for instance.
Scalar types, such as `Optional` and `ResilientRawRepresentable`, also provide an `error` property. Developers can determine if an error ocurred during decoding by accessing `$foo.error` for a property written `@Resilient var foo: Int?`.
`@Resilient` array properties provide two additional fields: `errors` and `results`. `errors` is the list of all errors that were recovered from when decoding the array. `results` interleaves these errors with elements of the array that were successfully decoded. For instance, the `results` for a property written `@Resilient var baz: [Int]` when decoding the JSON snippet `[1, 2, "3"]` would be two `.success` values followed by a `.failure`.

### `ResilientDecodingErrorReporter`

In production, `ResilientDecodingErrorReporter` can be used to collate all errors encountered when decoding a type with `Resilient` properties. `JSONDecoder` provides a convenient `decode(_:from:reportResilientDecodingErrors:)` API which returns both the decoded value and the error digest if errors were encountered. More complex use cases require adding a `ResilientDecodingErrorReporter` to your `Decoder`'s `userInfo` as the value for the `.resilientDecodingErrorReporter` user info key. After decoding a type, you can call `flushReportedErrors` which will return an `ErrorDigest` if any errors are encountered. The digest can be used to access the underlying errors (`errorDigest.errors`) or be pretty-printed in `DEBUG` (`debugPrint(errorDigest)`). 

The pretty-printed digest looks something like this:
```
resilientArrayProperty
  Index 1
    - Could not decode as `Int`
  Index 3
    - Could not decode as `Int`
resilientRawRepresentableProperty
  - Unknown novel value "novel" (this error is not reported by default)
```

**Note:** One difference the errors available on the property wrapper and those reported to the `ResilientDecodingErrorReporter`, is the latter _does not_ report `UnknownNovelValueError`s by default (`UnknownNovelValueError` is thrown when a non-frozen `ResilientRawRepresentable`'s `init(rawValue:)` returns `nil`). You can alter this behavior by calling `errors(includeUnknownNovelValueErrors: true)` on the error digest. 

## More Details

For more information about what how exactly a particular `Resilient` field will behave when it encounters a particular error, I recommend consulting the unit tests.
