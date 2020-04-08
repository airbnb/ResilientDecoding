// Created by George Leontiev on 3/31/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

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
public protocol ResilientRawRepresentable: Decodable, RawRepresentable where RawValue: Decodable {

  associatedtype DecodingFallback

  /**
   This value will be used when decoding a `Resilient<Self>` fails. For types overriding this property, the type should only ever be `Self`
   `ResilientRawRepresentable` types do not provide a `decodingFallback` by default. This is indicated by the associated `DecodingFallback` type being `Void`.
   - note: The `decodingFallback` will not be used if you are decoding an array where the element is a `ResilientRawRepresentable` type. Instead, they will be omitted.
   */
  static var decodingFallback: DecodingFallback { get }

  /**
   Override this property to return `true` to report errors when encountering a `RawValue` that doesn _not_ correspond to a value of this type. Failure to decode the `RawValue` will _always_ report an error.
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
      ResilientRawRepresentableContainer<T>.self,
      forKey: key,
      fallback: .decodingFallback,
      options: [])
        .map { $0.value }
  }

  /**
   Decodes a `ResilientRawRepresentable` optional.
   This is different from simply decoding a `Resilient` optional because non-frozen `enum` types will not report errors.
   */
  public func decode<T: ResilientRawRepresentable>(_ type: Resilient<T?>.Type, forKey key: Key) throws -> Resilient<T?>
    where
      T.DecodingFallback == Void
  {
    resilientlyDecode(ResilientRawRepresentableContainer<T>?.self, forKey: key)
      .map { $0.map { $0.value } }
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
      options: .behaveLikeOptional,
      decode: { decoder in
        do {
          return Resilient(try ResilientRawRepresentableContainer(from: decoder).value)
        } catch {
          return decoder.resilient(T.decodingFallback, error: error)
        }
      })
  }

  /**
   When decoding an array of `ResilientRawRepresentable` values,  elements are omitted as errors are encountered. The `decodingFallback` is never used.
   */
  public func decode<T: ResilientRawRepresentable>(_ type: Resilient<[T]>.Type, forKey key: Key) throws -> Resilient<[T]>
  {
    resilientlyDecodeArray(of: ResilientRawRepresentableContainer<T>.self, forKey: key)
      .map { array in
        array.map { container in
          container.value
        }
      }
  }

  /**
   When decoding an array of `ResilientRawRepresentable` values,  elements are omitted as errors are encountered. The `decodingFallback` is never used.
   */
  public func decode<T: ResilientRawRepresentable>(_ type: Resilient<[T]?>.Type, forKey key: Key) throws -> Resilient<[T]?>
  {
    resilientlyDecodeArray(of: ResilientRawRepresentableContainer<T>.self, forKey: key)
      .map { optionalArray in
        optionalArray.map { array in
          array.map { container in
            container.value
          }
        }
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
    if Value.isFrozen {
      value = try Value(from: decoder)
    } else {
      let rawValue = try Value.RawValue(from: decoder)
      if let value = Value(rawValue: rawValue) {
        self.value = value
      } else {
        throw UnknownNovelValueError(novelValue: rawValue)
      }
    }
  }
  private init(_ value: Value) {
    self.value = value
  }
}

private extension ResilientRawRepresentableContainer where Value.DecodingFallback == Value {
  static var decodingFallback: ResilientRawRepresentableContainer {
    ResilientRawRepresentableContainer(Value.decodingFallback)
  }
}
