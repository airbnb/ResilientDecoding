// Created by George Leontiev on 3/31/20.
// Copyright © 2020 Airbnb Inc.

import Foundation

/**
 A type that can be made `Resilient`

 For instance, if you declare the type
 ```
 enum MyEnum: ResilientRawRepresentable {
   case existing
   case unknown
   static let decodingFallback: MyEnum = .unknown
 }
 ```
 then any struct with a `Resilient` property with that type (for instance `@Resilient var myEnum: MyEnum`) will be set to `.unknown` in the event of a decoding failure.
 */
public protocol ResilientRawRepresentable: Decodable, Sendable, RawRepresentable where RawValue: Decodable & Sendable {

  associatedtype DecodingFallback

  /**
   This value will be used when decoding a `Resilient<Self>` fails. For types overriding this property, the type should only ever be `Self`
   `ResilientRawRepresentable` types do not provide a `decodingFallback` by default. This is indicated by the associated `DecodingFallback` type being `Void`.
   - note: The `decodingFallback` will not be used if you are decoding an array where the element is a `ResilientRawRepresentable` type. Instead, they will be omitted.
   */
  static var decodingFallback: DecodingFallback { get }

  /**
   Override this property to return `true` to report errors when encountering a `RawValue` that does _not_ correspond to a value of this type. Failure to decode the `RawValue` will _always_ report an error.
   Defaults to `false`.
   */
  static var isFrozen: Bool { get }

}

/**
 Default implementations of protocol requirements
 */
extension ResilientRawRepresentable {
  public static var isFrozen: Bool { false }
  public static var decodingFallback: Void { () }
}

// MARK: - Decoding

/**
 Synthesized `Decodable` initializers are effectively equivalent to writing the following initializer:
 ```
 init(from decoder: Decoder) throws {
   let container = try decoder.container(keyedBy: SynthesizedCodingKeys.self)
   self.propertyA = try container.decode(TypeOfPropertyA.self, forKey: .propertyA)
   self.propertyB = try container.decode(TypeOfPropertyB.self, forKey: .propertyB)
   …and so on
 }
 ```
 By declaring these public methods here, if `TypeOfPropertyA` is a specialization of `Resilient` such that it matches one of the following method signatures, Swift will call that overload of the `decode(_:forKey)` method instead of the default implementation provided by `Foundation`. This allows us to perform custom logic to _resiliently_ recover from decoding errors.
 */
extension KeyedDecodingContainer {

  /**
   Decodes a `ResilientRawRepresentable` type which provides a custom `decodingFallback`.
   */
  public func decode<T: ResilientRawRepresentable>(_ type: Resilient<T>.Type, forKey key: Key) throws -> Resilient<T>
    where
      T.DecodingFallback == T
  {
    resilientlyDecode(
      valueForKey: key,
      fallback: .decodingFallback,
      /// For a non-optional `ResilientRawRepresentable`, a missing key or `nil` value are considered errors
      behaveLikeOptional: false,
      body: { Resilient(try ResilientRawRepresentableContainer(from: $0).value) })
  }

  /**
   Decodes a `ResilientRawRepresentable` optional.
   This is different from simply decoding a `Resilient` optional because non-frozen `enum` types will not report errors.
   */
  public func decode<T: ResilientRawRepresentable>(_ type: Resilient<T?>.Type, forKey key: Key) throws -> Resilient<T?>
    where
      T.DecodingFallback == Void
  {
    resilientlyDecode(
      valueForKey: key,
      fallback: nil,
      body: { Resilient(try ResilientRawRepresentableContainer(from: $0).value).map { $0 } })
  }

  /**
   Decodes a `ResilientRawRepresentable` optional which provides a `decodingFallback`.
   This is different from simply decoding a `Resilient` optional because non-frozen `enum` types will not report errors.
   - note: The `Resilient` value will be `nil`, if we decode `nil` for this key or the key is missing. In all other cases we use `T.decodingFallback`.
   */
  public func decode<T: ResilientRawRepresentable>(_ type: Resilient<T?>.Type, forKey key: Key) throws -> Resilient<T?>
    where
      T.DecodingFallback == T
  {
    resilientlyDecode(
      valueForKey: key,
      fallback: nil,
      body: { decoder in
        do {
          return Resilient(try ResilientRawRepresentableContainer(from: decoder).value).map { $0 }
        } catch {
          decoder.reportError(error)
          return Resilient(T.decodingFallback, outcome: .recoveredFrom(error, wasReported: true))
        }
      })
  }

  /**
   When decoding an array of `ResilientRawRepresentable` values,  elements are omitted as errors are encountered. The `decodingFallback` is never used.
   */
  public func decode<T: ResilientRawRepresentable>(_ type: Resilient<[T]>.Type, forKey key: Key) throws -> Resilient<[T]>
  {
    resilientlyDecode(valueForKey: key, fallback: []) { decoder in
      decoder.resilientlyDecodeArray(
        of: ResilientRawRepresentableContainer.self,
        transform: { $0.value })
      }
  }

  /**
   When decoding an array of `ResilientRawRepresentable` values,  elements are omitted as errors are encountered. The `decodingFallback` is never used.
   */
  public func decode<T: ResilientRawRepresentable>(_ type: Resilient<[T]?>.Type, forKey key: Key) throws -> Resilient<[T]?>
  {
    resilientlyDecode(valueForKey: key, fallback: nil) { decoder in
      decoder.resilientlyDecodeArray(
        of: ResilientRawRepresentableContainer.self,
        transform: { $0.value })
        /// Transforms `Resilient<[String: T]>` into `Resilient<[String: T]?>`
        .map { $0 }
    }
  }

  /**
   When decoding a dictionary of `ResilientRawRepresentable` values,  elements are omitted as errors are encountered. The `decodingFallback` is never used.
   */
  public func decode<T: ResilientRawRepresentable>(_ type: Resilient<[String: T]>.Type, forKey key: Key) throws -> Resilient<[String: T]>
  {
    resilientlyDecode(valueForKey: key, fallback: [:]) { decoder in
      decoder.resilientlyDecodeDictionary(
        of: ResilientRawRepresentableContainer.self,
        transform: { $0.value })
      }
  }

  /**
   When decoding a dictionary of `ResilientRawRepresentable` values,  elements are omitted as errors are encountered. The `decodingFallback` is never used.
   */
  public func decode<T: ResilientRawRepresentable>(_ type: Resilient<[String: T]?>.Type, forKey key: Key) throws -> Resilient<[String: T]?>
  {
    resilientlyDecode(valueForKey: key, fallback: nil) { decoder in
      decoder.resilientlyDecodeDictionary(
        of: ResilientRawRepresentableContainer.self,
        transform: { $0.value })
        /// Transforms `Resilient<[String: T]>` into `Resilient<[String: T]?>`
        .map { $0 }
    }
  }


}

// MARK: - Catch Common Mistakes

extension KeyedDecodingContainer {

  /**
   If a type does not provide a `decodingFallback`, it cannot be resiliently decoded unless the property is marked optional.
   */
  public func decode<T: ResilientRawRepresentable>(_ type: Resilient<T>.Type, forKey key: Key) throws -> Resilient<T>
    where
      T.DecodingFallback == Void
  {
    assertionFailure()
    return Resilient(try decode(T.self, forKey: key))
  }

  /**
   This method will be called if a `ResilientRawRepresentable` type defines a `decodingFallback` that isn't `Void` or `Self`. This is likely a mistake, since only those types affect the behavior of `ResilientRawRepresentable`.
   */
  public func decode<T: ResilientRawRepresentable>(_ type: Resilient<T>.Type, forKey key: Key) throws -> Resilient<T>
  {
    assertionFailure()
    return Resilient(try decode(T.self, forKey: key))
  }

}

// MARK: - Private

private struct ResilientRawRepresentableContainer<Value: ResilientRawRepresentable>: Decodable {
  let value: Value
  init(from decoder: Decoder) throws {
    let rawValue = try decoder.singleValueContainer().decode(Value.RawValue.self)
    if let value = Value(rawValue: rawValue) {
      self.value = value
    } else {
      if Value.isFrozen {
        /**
         Ideally, we would just call `try Value(from: decoder)` at the top of this function if `Value.isFrozen` and use the error thrown by `Foundation`. Unfortunately, this fails when decoding a type whose `RawValue` is backed by primitive type (like how `URL` is backed by `String`). The URL test in `BugTests` demonstrates this behavior. I believe it is related to this issue: https://forums.swift.org/t/url-fails-to-decode-when-it-is-a-generic-argument-and-genericargument-from-decoder-is-used/36238
         */
        let context = DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Cannot initialize \(Value.self) from invalid raw value \(rawValue)")
        throw DecodingError.dataCorrupted(context)
      } else {
        throw UnknownNovelValueError(novelValue: rawValue)
      }
    }
  }
}
