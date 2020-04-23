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
   Decodes a `Resilient` dictionary, omitting elements as errors are encountered.
   */
  public func decode<Element>(_ type: Resilient<[String: Element]>.Type, forKey key: Key) throws -> Resilient<[String: Element]>
  {
    resilientlyDecode(valueForKey: key, fallback: [:]) { $0.resilientlyDecodeDictionary() }
  }

  /**
   Decodes an optional `Resilient` dictionary. A missing key or `nil` value will silently set the property to `nil`.
   */
  public func decode<Element: Decodable>(_ type: Resilient<[String: Element]?>.Type, forKey key: Key) throws -> Resilient<[String: Element]?> {
    resilientlyDecode(valueForKey: key, fallback: nil) { $0.resilientlyDecodeDictionary().map { $0 } }
  }

}

extension Decoder {

  func resilientlyDecodeDictionary<Element: Decodable>() -> Resilient<[String: Element]>
  {
    resilientlyDecodeDictionary(of: Element.self, transform: { $0 })
  }

  func resilientlyDecodeDictionary<IntermediateElement: Decodable, Element>(
    of elementType: IntermediateElement.Type,
    transform: (IntermediateElement) -> Element) -> Resilient<[String: Element]>
  {
    do {
      let value = try singleValueContainer()
        .decode([String: DecodingResultContainer<IntermediateElement>].self)
        .mapValues { $0.result.map(transform) }
      return Resilient(value)
    } catch {
      resilientDecodingHandled(error)
      return Resilient([:], outcome: .recoveredFrom(error, wasReported: true))
    }
  }

}

// MARK: - Private

/**
 We can't use `KeyedDecodingContainer` to decode a dictionary because it will use `keyDecodingStrategy` to map the keys, which dictionary values do not. Instead we pull out the element decoders using this wrapper type.
 */
private struct DecodingResultContainer<Success: Decodable>: Decodable {
  let result: Result<Success, Error>
  init(from decoder: Decoder) throws {
    result =  Result {
       do {
         return try Success(from: decoder)
       } catch {
         decoder.resilientDecodingHandled(error)
         throw error
       }
     }
  }
}
