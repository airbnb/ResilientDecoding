// Created by George Leontiev on 4/19/20.
// Copyright © 2020 Airbnb Inc.

import Foundation

extension Resilient {
  
  init<T: Sendable>(_ results: [Result<T, Error>]) where Value == [T] {
    self.init(results, transform: { $0 })
  }
  
  init<T: Sendable>(_ results: [Result<T, Error>]) where Value == [T]? {
    self.init(results, transform: { $0 })
  }

  /**
   - parameter transform: While the two lines above both say `{ $0 }` they are actually different because the first one is of type `([T]) -> [T]` and the second is of type `([T]) -> [T]?`.
   */
  private init<T: Sendable>(_ results: [Result<T, Error>], transform: ([T]) -> Value) {
    let elements = results.compactMap { try? $0.get() }
    let value = transform(elements)
    if elements.count == results.count {
      self.init(value, outcome: .decodedSuccessfully)
    } else {
      #if DEBUG
      let error = ResilientDecodingOutcome.ArrayDecodingError(results: results)
      /// `ArrayDecodingError` is not reported
      self.init(value, outcome: .recoveredFrom(error, wasReported: false))
      #else
      self.init(value, outcome: .recoveredFromDebugOnlyError)
      #endif
    }
  }

}

#if DEBUG

extension ResilientDecodingOutcome {
  
  /**
   A type representing some number of errors encountered while decoding an array
   */
  public struct ArrayDecodingError<Element: Sendable>: Error {
    public let results: [Result<Element, Error>]
    public var errors: [Error] {
      results.compactMap { result in
        switch result {
        case .success:
          return nil
        case .failure(let error):
          return error
        }
      }
    }
    /// `ArrayDecodingError` should only be initialized in this file
    fileprivate init(results: [Result<Element, Error>]) {
      self.results = results
    }
  }
  
  /**
   Creates an `ArrayDecodingError` representation of this outcome.
   */
  fileprivate func arrayDecodingError<T>() -> ResilientDecodingOutcome.ArrayDecodingError<T> {
    typealias ArrayDecodingError = ResilientDecodingOutcome.ArrayDecodingError<T>
    switch self {
    case .decodedSuccessfully, .keyNotFound, .valueWasNil:
      return .init(results: [])
    case let .recoveredFrom(error as ArrayDecodingError, wasReported):
      /// `ArrayDecodingError` should not be reported
      assert(!wasReported)
      return error
    case .recoveredFrom(let error, _):
      /// When recovering from a top level error, we can provide the error value in the array, instead of returning an empty array. We believe this is a win for usability.
      return .init(results: [.failure(error)])
    }
  }
  
}

extension Resilient.ProjectedValue {
  
  /**
   This subscript adds the `errors` and `results` property to `Resilient<[T]>` values using `dynamicMemberLookup`.
   */
  public subscript<T, U>(
    dynamicMember keyPath: KeyPath<ResilientDecodingOutcome.ArrayDecodingError<T>, U>) -> U
    where Value == [T]
  {
    outcome.arrayDecodingError()[keyPath: keyPath]
  }
  
  /**
   This subscript adds the `errors` and `results` property to `Resilient<[T]>` values using `dynamicMemberLookup`.
   */
  public subscript<T, U>(
    dynamicMember keyPath: KeyPath<ResilientDecodingOutcome.ArrayDecodingError<T>, U>) -> U
    where Value == [T]?
  {
    outcome.arrayDecodingError()[keyPath: keyPath]
  }

}

#endif
