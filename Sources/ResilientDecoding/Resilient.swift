// Created by George Leontiev on 3/24/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation

// MARK: - Resilient

@propertyWrapper
public struct Resilient<Value: Decodable>: Decodable {

  /**
   If this initializer is called it is likely because a property was marked as `Resilient` despite the underlying type not supporting resilient decoding. For instance, a developer may write `@Resilient var numberOfThings: Int`, but since `Int` doesn't provide a mechanism for recovering from a decoding failure (like `Array`s and `Optional`s do) wrapping the property in `Resilient` does nothing.
   If this happens in production, we decode the wrapped value the same way we would if it wasn't `Resilient`, and if an error is thrown it proceeds up the stack uncaught by the mechanisms of `Resilient`. Since it is unlikely that this is what the developer intended, we `assert` in debug to give the developer a chance to fix their mistake, potentially rewriting the example above as `@Resilient var numberOfThings: Int?` (which would catch decoding errors and set `numberOfThings` to `nil`.
   */
  public init(from decoder: Decoder) throws {
    assertionFailure()
    let value = try Value(from: decoder)
    self = Self(value, outcome: .decodedSuccessfully)
  }

  /**
   Initialized a `Resilient` value as though it had been decoded without encountering any errors.
   */
  public init(_ value: Value) {
    self.wrappedValue = value
    self.outcome = .decodedSuccessfully
  }
    
  init(_ value: Value, outcome: ResilientDecodingOutcome) {
    self.wrappedValue = value
    self.outcome = outcome
  }

  public let wrappedValue: Value

  let outcome: ResilientDecodingOutcome

  /**
   Transforms the value of a `Resilient` type.
   If `self` is a resilient array,  care should be taken to ensure that the `value.count` == `transform(value).count` in order to not break the `results` property.
   */
  func map<T>(transform: (Value) -> T) -> Resilient<T> {
    Resilient<T>(transform(wrappedValue), outcome: outcome)
  }
  
  #if DEBUG
  @dynamicMemberLookup
  public struct ProjectedValue {
    public let outcome: ResilientDecodingOutcome
    
    public var error: Error? {
      switch outcome {
      case .decodedSuccessfully, .keyNotFound, .valueWasNil:
        return nil
      case .recoveredFrom(let error, _):
        return error
      }
    }
  }
  public var projectedValue: ProjectedValue { ProjectedValue(outcome: outcome) }
  #endif
  
}

// MARK: - Decoding Outcome

#if DEBUG
public enum ResilientDecodingOutcome {
  case decodedSuccessfully
  case keyNotFound
  case valueWasNil
  
  /// https://github.com/apple/swift/blob/88b093e9d77d6201935a2c2fb13f27d961836777/stdlib/public/Darwin/Foundation/JSONEncoder.swift#L1657-L1661
  case recoveredFrom(Error, wasReported: Bool)
}
#else
struct ResilientDecodingOutcome {
  static let decodedSuccessfully = Self()
  static let keyNotFound = Self()
  static let valueWasNil = Self()
  static let recoveredFromDebugOnlyError = Self()
  static func recoveredFrom(_: Error, wasReported: Bool) -> Self { Self() }
}
#endif

// MARK: - Convenience

extension KeyedDecodingContainer {

  /**
   Resiliently decodes a value for the specified key, using `fallback` if an error is encountered.
   This form allows the caller to provide their own `Resilient` with custom errors, which is only used for `ResilientArray` and `ResilientRawRepresentable` optionals that define a `decodingFallback`.
   */
  func resilientlyDecode<T: Decodable>(
    valueForKey key: Key,
    fallback: @autoclosure () -> T,
    behaveLikeOptional: Bool = true,
    body: (Decoder) throws -> Resilient<T> = { Resilient(try T(from: $0)) }) -> Resilient<T>
  {
    if behaveLikeOptional, !contains(key) {
      return Resilient(fallback(), outcome: .keyNotFound)
    }
    do {
      let decoder = try superDecoder(forKey: key)
      do {
        if behaveLikeOptional, try decoder.singleValueContainer().decodeNil() {
          return Resilient(fallback(), outcome: .valueWasNil)
        }
        return try body(decoder)
      } catch {
        decoder.resilientDecodingHandled(error)
        return Resilient(fallback(), outcome: .recoveredFrom(error, wasReported: true))
      }
    } catch {
      return Resilient(fallback(), outcome: .recoveredFrom(error, wasReported: false))
    }
  }

}
