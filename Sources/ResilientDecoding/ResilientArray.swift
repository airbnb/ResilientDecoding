// Created by George Leontiev on 3/31/20.
// Copyright © 2020 Airbnb Inc.

import Foundation

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
 By declaring these `public` methods here, if `TypeOfPropertyA` is a specialization of `Resilient` such that it matches one of the following method signatures, Swift will call that overload of the `decode(_:forKey)` method instead of the default implementation provided by `Foundation`. This allows us to perform custom logic to _resiliently_ recover from decoding errors.
 */
extension KeyedDecodingContainer {

  /**
   Decodes a `Resilient` array, omitting elements as errors are encountered.
   */
  public func decode<Element>(_ type: Resilient<[Element]>.Type, forKey key: Key) throws -> Resilient<[Element]>
    where
      Element: Decodable
  {
    resilientlyDecode(valueForKey: key, fallback: []) { $0.resilientlyDecodeArray() }
  }

  /**
   Decodes an optional `Resilient` array. A missing key or `nil` value will silently set the property to `nil`.
   */
  public func decode<Element: Decodable>(_ type: Resilient<[Element]?>.Type, forKey key: Key) throws -> Resilient<[Element]?> {
    resilientlyDecode(valueForKey: key, fallback: nil) { $0.resilientlyDecodeArray().map { $0 } }
  }

}

extension Decoder {

  func resilientlyDecodeArray<Element: Decodable>() -> Resilient<[Element]>
  {
    resilientlyDecodeArray(of: Element.self, transform: { $0 })
  }

  /**
   We can't just use `map` because the transform needs to happen _before_ we wrap the value in `Resilient` so that that the element type of `ArrayDecodingError` is correct.
   */
  func resilientlyDecodeArray<IntermediateElement: Decodable, Element>(
    of intermediateElementType: IntermediateElement.Type,
    transform: (IntermediateElement) -> Element) -> Resilient<[Element]>
  {
    do {
      var container = try unkeyedContainer()
      var results: [Result<Element, Error>] = []
      if let count = container.count {
        results.reserveCapacity(count)
      }
      while !container.isAtEnd {
        /// It is very unlikely that an error will be thrown here, so it is fine that this would fail the entire array
        let elementDecoder = try container.superDecoder()
        do {
          results.append(.success(transform(try IntermediateElement(from: elementDecoder))))
        } catch {
          elementDecoder.resilientDecodingHandled(error)
          results.append(.failure(error))
        }
      }
      return Resilient(results)
    } catch {
      resilientDecodingHandled(error)
      return Resilient([], outcome: .recoveredFrom(error, wasReported: true))
    }
  }

}

// MARK: - Catch Common Mistakes

/**
 For the following cases, the user probably meant to use `[T]` as the property type.
 */
extension KeyedDecodingContainer {
  public func decode<T: Decodable>(_ type: Resilient<[T?]>.Type, forKey key: Key) throws -> Resilient<[T?]> {
    assertionFailure()
    return try decode(Resilient<[T]>.self, forKey: key).map { $0 }
  }
  public func decode<T: Decodable>(_ type: Resilient<[T?]?>.Type, forKey key: Key) throws -> Resilient<[T?]?> {
    assertionFailure()
    return try decode(Resilient<[T]>.self, forKey: key).map { $0 }
  }
}
