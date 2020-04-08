// Created by George Leontiev on 3/24/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation

// MARK: - Public

@propertyWrapper
public struct Resilient<Value: Decodable>: Decodable {

  /**
   If this initializer is called it is likely because a property was marked as `Resilient` despite the underlying type not supporting resilient decoding. For instance, a developer may write `@Resilient var numberOfThings: Int`, but since `Int` doesn't provide a mechanism for recovering from a decoding failure (like `Array`s and `Optional`s do) wrapping the property in `Resilient` does nothing.
   If this happens in production, we decode the wrapped value the same way we would if it wasn't `Resilient`, and if an error is thrown it proceeds up the stack uncaught by the mechanisms of `Resilient`. Since it is unlikely that this is what the developer intended, we `assert` in debug to give the developer a chance to fix their mistake, potentially rewriting the example above as `@Resilient var numberOfThings: Int?` (which would catch decoding errors and set `numberOfThings` to `nil`.
   */
  public init(from decoder: Decoder) throws {
    assertionFailure()
    let value = try Value(from: decoder)
    self = Self(value)
  }

  /**
   Initialized a `Resilient` value as though it had been decoded without encountering any errors.
   */
  public init(_ value: Value) {
    wrappedValue = value
    #if DEBUG
    projectedValue = ProjectedValue(value: value, topLevelError: nil, errorsAtOffset: [])
    #endif
  }

  #if DEBUG

  fileprivate init(
    value: Value,
    topLevelError: Error?,
    errorsAtOffset: [ErrorAtOffset])
  {
    wrappedValue = value
    projectedValue = ProjectedValue(value: value, topLevelError: topLevelError, errorsAtOffset: errorsAtOffset)
  }

  public struct ProjectedValue {
    let value: Value

    let topLevelError: Error?

    /**
     This array will only be non-empty when `Value` is an `Array`. It is meant to be accessed via the `results` or `errors` property.
     */
    let errorsAtOffset: [ErrorAtOffset]
  }
  public let projectedValue: ProjectedValue

  #endif

  public let wrappedValue: Value

  /**
   Transforms the value of a `Resilient` type.
   If `wrappedValue` is an array,  care should be taken to ensure that the `value.count` == `transform(value).count` in order to not break the `results` property.
   */
  func map<T>(transform: (Value) -> T) -> Resilient<T> {
    let value = transform(wrappedValue)
    #if DEBUG
    return Resilient<T>(
      value: value,
      topLevelError: projectedValue.topLevelError,
      errorsAtOffset: projectedValue.errorsAtOffset)
    #else
    return Resilient<T>(value)
    #endif
  }
}

// MARK: - Creating Resilient Values

extension Decoder {

  /**
   Creates a `Resilient` value with a fallback value after an error has occurred and reports the error to `ResilientDecodingErrorReporter`.
   Since this is the only way to create a `Resilient` with an error, this ensures we are reporting all errors encountered in this manner.
   */
  func resilient<T>(_ fallbackValue: T, error: Error) -> Resilient<T> {
    resilientDecodingHandled(error)
    #if DEBUG
      return Resilient(
        value: fallbackValue,
        topLevelError: error,
        errorsAtOffset: [])
    #else
      return Resilient(fallbackValue)
    #endif
  }

}

extension Resilient where Value: Collection {

  #if DEBUG
  /**
   Creates a `Resilient` value with a partial value, and the errors which caused some elements to be omitted.
   - note: Unlike `Decoder.resilient(_:error)`, the caller is responsible for ensuring the errors in `errorsAtOffset` are reported using `Decoder.resilientDecodingErrorHandled`.
   */
  init(_ partialValue: Value, errorsAtOffset: [ErrorAtOffset]) {
    precondition(!errorsAtOffset.isEmpty)
    wrappedValue = partialValue
    projectedValue = ProjectedValue(
      value: partialValue,
      topLevelError: nil,
      errorsAtOffset: errorsAtOffset)
  }
  #endif

}

// MARK: - Decoding

struct ResilientDecodingOptions: OptionSet {
  let rawValue: Int
  static let suppressKeyNotFoundError = ResilientDecodingOptions(rawValue: 1 << 0)
  static let suppressValueNotFoundError = ResilientDecodingOptions(rawValue: 1 << 1)
  static let behaveLikeOptional: ResilientDecodingOptions = [.suppressKeyNotFoundError, .suppressValueNotFoundError]
}

extension KeyedDecodingContainer {

  /**
   Resiliently decodes a value for the specified key, using `fallback` if an error is encountered.
   */
  func resilientlyDecode<T: Decodable>(
    _ type: T.Type,
    forKey key: Key,
    fallback: @autoclosure () -> T,
    options: ResilientDecodingOptions) -> Resilient<T>
  {
    resilientlyDecode(
      valueForKey: key,
      fallback: fallback(),
      options: options,
      decode: { Resilient(try T(from: $0)) })
  }

  /**
   Resiliently decodes a value for the specified key, using `fallback` if an error is encountered.
   */
  func resilientlyDecode<T: Decodable>(
    _ type: T?.Type,
    forKey key: Key) -> Resilient<T?>
  {
    resilientlyDecode(
      T?.self,
      forKey: key,
      fallback: nil,
      options: .behaveLikeOptional)
  }

  /**
   Resiliently decodes a value for the specified key, using `fallback` if an error is encountered.
   This form allows the caller to provide their own `Resilient` with custom errors, which is only used for `ResilientArray` and `ResilientRawRepresentable` optionals that define a `decodingFallback`.
   */
  func resilientlyDecode<T>(
    valueForKey key: Key,
    fallback: @autoclosure () -> T,
    options: ResilientDecodingOptions,
    decode: (Decoder) throws -> Resilient<T>) -> Resilient<T>
  {
    if options.contains(.suppressKeyNotFoundError), !contains(key) {
      return Resilient(fallback())
    }
    do {
      let decoder = try superDecoder(forKey: key)
      do {
        if
          options.contains(.suppressValueNotFoundError),
          try decoder.singleValueContainer().decodeNil()
        {
          return Resilient(fallback())
        }
        return try decode(decoder)
      } catch {
        return decoder.resilient(fallback(), error: error)
      }
    } catch {
      #if DEBUG
        /// No other place in the code is allowed to use an `UnreportableError`
        return Resilient(value: fallback(), topLevelError: UnreportableError(error), errorsAtOffset: [])
      #else
        return Resilient(fallback())
      #endif
    }
  }

}

#if DEBUG

/**
 This signifies that we encountered an error we cannot report.
 This is highly unlikely since we verify that the specified key exists before calling `superDecoder(forKey:)`, though we cannot guarantee this since we might be provided a custom `Decoder` implementation.
 */
private struct UnreportableError: Error {
  init(_ error: Error) {
    assertionFailure()
    self.error = error
  }
  let error: Error
}

#endif
