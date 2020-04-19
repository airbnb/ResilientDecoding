// Created by George Leontiev on 4/19/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation

extension Resilient {
  
  init<T>(_ results: [Result<T, Error>]) where Value == [T] {
    self.init(results, transform: { $0 })
  }
  
  init<T>(_ results: [Result<T, Error>]) where Value == [T]? {
    self.init(results, transform: { $0 })
  }

  private init<T>(_ results: [Result<T, Error>], transform: ([T]) -> Value) {
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
  public struct ArrayDecodingError<Element>: Error {
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
  
  fileprivate func arrayDecodingError<T>(_ elementType: T.Type = T.self) -> ResilientDecodingOutcome.ArrayDecodingError<T> {
    typealias ArrayDecodingError = ResilientDecodingOutcome.ArrayDecodingError<T>
    switch self {
    case .decodedSuccessfully, .keyNotFound, .valueWasNil:
      return .init(results: [])
    case let .recoveredFrom(error as ArrayDecodingError, wasReported):
      assert(!wasReported)
      return error
    case .recoveredFrom(let error, _):
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
