// Created by George Leontiev on 3/31/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

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
   Decodes a `Resilient` array, omitting elements as errors are encountered. A missing key or `nil` value are treated as errors when using a non-optional array.
   */
  public func decode<Element>(_ type: Resilient<[Element]>.Type, forKey key: Key) throws -> Resilient<[Element]>
    where
      Element: Decodable
  {
    resilientlyDecodeArray(of: Element.self, forKey: key)
  }

  /**
   Decodes an optional `Resilient` array. A missing key or `nil` value will silently set the property to `nil`.
   */
  public func decode<Element: Decodable>(_ type: Resilient<[Element]?>.Type, forKey key: Key) throws -> Resilient<[Element]?> {
    resilientlyDecodeArray(of: Element.self, forKey: key)
  }

  /**
   Internal version of `decode(_:forKey:)`.
   You can achieve the same effect by calling `decode(_:forKey:)` with the propery type argument, but this is more explicit.
   */
  func resilientlyDecodeArray<Element: Decodable>(of elementType: Element.Type, forKey key: Key) -> Resilient<[Element]> {
    resilientlyDecode(
      valueForKey: key,
      fallback: [],
      options: .behaveLikeOptional,
      decode: { $0.resilientlyDecodeArray() })
  }

  /**
   Internal version of `decode(_:forKey:)`.
   You can achieve the same effect by calling `decode(_:forKey:)` with the propery type argument, but this is more explicit.
   */
  func resilientlyDecodeArray<Element: Decodable>(of elementType: Element.Type, forKey key: Key) -> Resilient<[Element]?> {
    resilientlyDecode(
      valueForKey: key,
      fallback: nil,
      options: .behaveLikeOptional,
      decode: { $0.resilientlyDecodeArray().map { $0 } })
  }

}

extension Decoder {

  func resilientlyDecodeArray<Element: Decodable>() -> Resilient<[Element]> {
    do {
      var container = try unkeyedContainer()
      var elements: [Element] = []
      if let count = container.count {
        elements.reserveCapacity(count)
      }
      #if DEBUG
      var errorsAtOffset: [ErrorAtOffset] = []
      #endif
      while !container.isAtEnd {
        /// It is very unlikely that an error will be thrown here, so it is fine that this would fail the entire array
        let elementDecoder = try container.superDecoder()
        do {
          /**
           We use `Element(from: container.superDecoder())` instead of `container.decode(Element.self)` here because the latter would not advance to the next element in the case of an error.
           */
          elements.append(try Element(from: elementDecoder))
        } catch {
          /**
           While this is similar to the catch block below, it is called on the _element_ decoder instead of the _array_ decoder so this error is registered as happening to the element.
           */
          elementDecoder.resilientDecodingHandled(error)
          #if DEBUG
          errorsAtOffset.append(ErrorAtOffset(offset: elements.count, error: error))
          #endif
        }
      }
      /**
       While we technically don't need this check, it makes debugging easier to only have code paths which encounter errors call the initializers that take error arguments. This enables developers to set breakpoints to catch partial failures without adding breakpoint conditions (which are slow).
       */
      #if DEBUG
      if errorsAtOffset.isEmpty {
        return Resilient(elements)
      } else {
        return Resilient(elements, errorsAtOffset: errorsAtOffset)
      }
      #else
      return Resilient(elements)
      #endif
    } catch {
      return resilient([], error: error)
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
