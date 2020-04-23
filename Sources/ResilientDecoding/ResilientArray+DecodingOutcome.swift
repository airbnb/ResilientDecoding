// Created by George Leontiev on 4/19/20.
// Copyright (c) 2020 Airbnb
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

extension Resilient {
  
  init<T>(_ results: [Result<T, Error>]) where Value == [T] {
    self.init(results, transform: { $0 })
  }
  
  init<T>(_ results: [Result<T, Error>]) where Value == [T]? {
    self.init(results, transform: { $0 })
  }

  /**
   - parameter transform: While the two lines above both say `{ $0 }` they are actually different because the first one is of type `([T]) -> [T]` and the second is of type `([T]) -> [T]?`.
   */
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
