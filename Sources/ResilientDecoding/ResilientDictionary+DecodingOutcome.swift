// Created by George Leontiev on 4/23/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation

extension Resilient {

  init<T>(_ results: [String: Result<T, Error>]) where Value == [String: T] {
    self.init(results, transform: { $0 })
  }

  init<T>(_ results: [String: Result<T, Error>]) where Value == [String: T]? {
    self.init(results, transform: { $0 })
  }

  /**
   - parameter transform: While the two lines above both say `{ $0 }` they are actually different because the first one is of type `([String: T]) -> [String: T]` and the second is of type `([String: T]) -> [String: T]?`.
   */
  private init<T>(_ results: [String: Result<T, Error>], transform: ([String: T]) -> Value) {
    let dictionary = results.compactMapValues { try? $0.get() }
    let value = transform(dictionary)
    if dictionary.count == results.count {
      self.init(value, outcome: .decodedSuccessfully)
    } else {
      #if DEBUG
      let error = ResilientDecodingOutcome.DictionaryDecodingError(topLevelError: nil, results: results)
      /// `DictionaryDecodingError` is not reported
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
   A type representing some number of errors encountered while decoding a dictionary
   */
  public struct DictionaryDecodingError<Value>: Error {
    public let results: [String: Result<Value, Error>]
    public var errors: [Error] {
      /// It is currently impossible to have both a `topLevelError` and `results` at the same time, but this code is simpler than having an `enum` nested in this type.
      [topLevelError].compactMap { $0 } + results.compactMap { pair in
        switch pair.value {
        case .success:
          return nil
        case .failure(let error):
          return error
        }
      }
    }

    /**
     Since we don't include the top level error in `results`, we have to store it separately.
     */
    private var topLevelError: Error?

    /// `DictionaryDecodingError` should only be initialized in this file
    fileprivate init(topLevelError: Error?, results: [String: Result<Value, Error>]) {
      self.topLevelError = topLevelError
      self.results = results
    }
  }

  /**
   Creates an `DictionaryDecodingError` representation of this outcome.
   */
  fileprivate func dictionaryDecodingError<T>() -> ResilientDecodingOutcome.DictionaryDecodingError<T> {
    typealias DictionaryDecodingError = ResilientDecodingOutcome.DictionaryDecodingError<T>
    switch self {
    case .decodedSuccessfully, .keyNotFound, .valueWasNil:
      return .init(topLevelError: nil, results: [:])
    case let .recoveredFrom(error as DictionaryDecodingError, wasReported):
      /// `DictionaryDecodingError` should not be reported
      assert(!wasReported)
      return error
    case .recoveredFrom(let error, _):
      /// Unlike array, we chose not to provide the top level error in the dictionary since there isn't a good way to choose an appropriate key.
      return .init(topLevelError: error, results: [:])
    }
  }

}

extension Resilient.ProjectedValue {

  /**
   This subscript adds the `errors` and `results` property to `Resilient<[String: T]>` values using `dynamicMemberLookup`.
   */
  public subscript<T, U>(
    dynamicMember keyPath: KeyPath<ResilientDecodingOutcome.DictionaryDecodingError<T>, U>) -> U
    where Value == [String: T]
  {
    outcome.dictionaryDecodingError()[keyPath: keyPath]
  }

  /**
   This subscript adds the `errors` and `results` property to `Resilient<[String: T]>` values using `dynamicMemberLookup`.
   */
  public subscript<T, U>(
    dynamicMember keyPath: KeyPath<ResilientDecodingOutcome.DictionaryDecodingError<T>, U>) -> U
    where Value == [String: T]?
  {
    outcome.dictionaryDecodingError()[keyPath: keyPath]
  }

}

#endif
