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
 By declaring these public methods here, if `TypeOfPropertyA` is a specialization of `Resilient` such that it matches one of the following method signatures, Swift will call that overload of the `decode(_:forKey)` method instead of the default implementation provided by `Foundation`. This allows us to perform custom logic to _resiliently_ recover from decoding errors.
 */
extension KeyedDecodingContainer {

  /**
   Decodes a `Resilient` value, substituting `nil` if an error is encountered (in most cases, this will be a `Resilient` `Optional` value).
   The synthesized `init(from:)` of a struct with a propery declared like this: `@Resilient var title: String?` will call this method to decode that property.
   */
  public func decode<T: Decodable>(_ type: Resilient<T?>.Type, forKey key: Key) throws -> Resilient<T?> {
    resilientlyDecode(T?.self, forKey: key)
  }

}
