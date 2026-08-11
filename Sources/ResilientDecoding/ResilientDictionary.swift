// Created by George Leontiev on 4/23/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation

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
 By declaring these `public` methods here, if `TypeOfPropertyA` is a specialization of `Resilient` such that it matches one of the following method signatures, Swift will call that overload of the `decode(_:forKey)` method instead of the default implementation provided by `Foundation`. This allows us to perform custom logic to _resiliently_ recover from decoding errors.
 */
extension KeyedDecodingContainer {

  /**
   Decodes a `Resilient` dictionary, omitting values as errors are encountered.
   */
  public func decode<Value: Sendable>(_ type: Resilient<[String: Value]>.Type, forKey key: Key) throws -> Resilient<[String: Value]>
  {
    resilientlyDecode(valueForKey: key, fallback: [:]) { $0.resilientlyDecodeDictionary() }
  }

  /**
   Decodes an optional `Resilient` dictionary. If the field is missing or the value is `nil` the decoded property will also be `nil`.
   */
  public func decode<Value: Decodable & Sendable>(_ type: Resilient<[String: Value]?>.Type, forKey key: Key) throws -> Resilient<[String: Value]?> {
    resilientlyDecode(valueForKey: key, fallback: nil) { $0.resilientlyDecodeDictionary().map { $0 } }
  }

}

extension Decoder {

  func resilientlyDecodeDictionary<Value: Decodable & Sendable>() -> Resilient<[String: Value]>
  {
    resilientlyDecodeDictionary(of: Value.self, transform: { $0 })
  }

  /**
   We can't just use `map` because the transform needs to happen _before_ we wrap the value in `Resilient` so that that the value type of `DictionaryDecodingError` is correct.
   */
  func resilientlyDecodeDictionary<IntermediateValue: Decodable, Value: Sendable>(
    of intermediateValueType: IntermediateValue.Type,
    transform: (IntermediateValue) -> Value) -> Resilient<[String: Value]>
  {
    do {
      let value = try singleValueContainer()
        .decode([String: DecodingResultContainer<IntermediateValue>].self)
        .mapValues { $0.result.map(transform) }
      return Resilient(value)
    } catch {
      reportError(error)
      return Resilient([:], outcome: .recoveredFrom(error, wasReported: true))
    }
  }

}

// MARK: - Private

/**
 We can't use `KeyedDecodingContainer` to decode a dictionary because it will use `keyDecodingStrategy` to map the keys, which dictionary values do not.
 */
private struct DecodingResultContainer<Success: Decodable>: Decodable {
  let result: Result<Success, Error>
  init(from decoder: Decoder) throws {
    result = Result {
      do {
        return try decoder.singleValueContainer().decode(Success.self)
      } catch {
        decoder.reportError(error)
        throw error
      }
    }
  }
}

// MARK: - Catch Common Mistakes

/**
 For the following cases, the user probably meant to use `[String: T]` as the property type.
 */
extension KeyedDecodingContainer {
  public func decode<T: Decodable & Sendable>(_ type: Resilient<[String: T?]>.Type, forKey key: Key) throws -> Resilient<[T?]> {
    assertionFailure()
    return try decode(Resilient<[T]>.self, forKey: key).map { $0 }
  }
  public func decode<T: Decodable & Sendable>(_ type: Resilient<[String: T?]?>.Type, forKey key: Key) throws -> Resilient<[T?]?> {
    assertionFailure()
    return try decode(Resilient<[T]>.self, forKey: key).map { $0 }
  }
}
