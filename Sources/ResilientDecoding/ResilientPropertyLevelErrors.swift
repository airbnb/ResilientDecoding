// Created by George Leontiev on 4/3/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation

/**
 The `Resilient` property wrapper has a `projectedValue` in `DEBUG` builds which contains the error(s) encountered when decoding that property. This is intended to only be used during development, error reporting in release should instead be done via `ResilientDecodingErrorReporter`.
 Limiting this functionality to `DEBUG` allows us to trade some extra complexity in this file for better [_clarity at point of use_](https://swift.org/documentation/api-design-guidelines/) and guarantee that this doesn't impact release builds.
 */

#if DEBUG
extension Resilient {
  public struct Projected {
    let value: Value

    enum
  }
}
#else
extension Resilient {
  public struct DecodingOutcome {
    let value: Value
  }
}
#endif

#if DEBUG

extension Resilient {

  @dynamicMemberLookup
  public struct PropertyLevelErrors {
    let decodedValue: Value

    /**
     The error encountered while decoding the value
     */
    public let error: Error?

    /**
     This type defines additional ways decoding errors can be inspected on `Resilient<[T]>` and `Resilient<[T]?>`
     The properties here are meant to be accessed directly on `PropertyLevelErrors` via `@dynamicMemberLookup`
     */
    public struct ArrayErrorDigest<Element> {
      
      /**
       An array of `Result` where elements that failed to decode are represented by `failure` case in the position where they would have occurred had the entire array been decoded successully.
       If the entire resilient array failed to decode, this will be a single failed `Result` with the top-level error.
       */
      public let results: [Result<Element, Error>]

      /**
       All errors encountered when decoding the resilient array, in no particular order.
       */
      public var errors: [Error] {
        return results.compactMap { result in
          guard case .failure(let error) = result else {
            return nil
          }
          return error
        }
      }

      fileprivate init(error: Error?, elements: [Element]) {
        switch error {
        case let error as ArrayDecodingError:
          results = error.errors(interleavedWith: elements)
        case let error?:
          results = [.failure(error)]
        case nil:
          results = []
        }
      }
    }

    /**
     This subscript adds the `errors` and `results` property to `Resilient<[T]>` values using `dynamicMemberLookup`.
     */
    public subscript<T, U>(dynamicMember keyPath: KeyPath<ArrayErrorDigest<T>, U>) -> U
      where
        Value == [T]
    {
      return ArrayErrorDigest(error: error, elements: decodedValue)[keyPath: keyPath]
    }

    /**
     This subscript adds the `errors` and `results` property to `Resilient<[T]?>` values using `dynamicMemberLookup`.
     */
    public subscript<T, U>(dynamicMember keyPath: KeyPath<ArrayErrorDigest<T>, U>) -> U
      where
        Value == [T]?
    {
      return ArrayErrorDigest(error: error, elements: decodedValue ?? [])[keyPath: keyPath]
    }
  }

}

// MARK: - Array Decoding Error

/**
 An error which represents any number of errors encountered when decoding a `Resilient` array.
 */
struct ArrayDecodingError: Error {

  /**
   Builds an `ArrayDecodingError`. This type assumes you are decoding elements in order, and care must be taken that the `mutating` members are called in the correct order.
   */
  struct Builder {
    private var index = 0
    private var arrayDecodingError = ArrayDecodingError()

    /**
     Signifies that an element was omitted due to a decoding error
     */
    mutating func failedToDecodeElement(dueTo error: Error) {
      arrayDecodingError.sortedErrorsAtOffset.append((index, error))
    }

    /**
     Signifies that an element was decoded successfully
     */
    mutating func decodedElement() {
      index += 1
    }

    /**
     Attempts to build the `ArrayDecodingError`, returns `nil` if all elements decoded successfully.
     */
    func build() -> ArrayDecodingError? {
      if arrayDecodingError.sortedErrorsAtOffset.isEmpty {
        return nil
      } else {
        return arrayDecodingError
      }
    }
  }

  /**
   This error must be constructed using `Builder`
   */
  fileprivate init() { }

  /**
   Interleaves encountered errors with the provided set of elements, potentially returning a single error in the case that the top-level decoding has failed.
   */
  fileprivate func errors<Value: Sequence>(interleavedWith value: Value) -> [Result<Value.Element, Error>] {
    /**
     `errorsAtOffset` are in the order the error was encountered, with the offset being the index where a successsfully decoded element would have been inserted. As a result, consecutive errors have the same offset as the subsequent successfully parsed element. We can thus recreate the original ordering by stably sorting an array of all errors followed by all values by their offset (a stable sort is a sort where the relative ordering of equal elements is preserved).
     */
    typealias ResultAtOffset = (offset: Int, element: Result<Value.Element, Error>)
    let resultsAtOffset: [ResultAtOffset] =
      sortedErrorsAtOffset.map { (offset: $0.offset, element: .failure($0.error)) }
        + value.map { .success($0) }.enumerated()
    /**
     The following code performs a stable sort of `resultsAtOffset`, since `Array.sorted()` is not guaranteed to be stable.
     */
    return resultsAtOffset
      .enumerated()
      .sorted { (first, second) -> Bool in
        if first.element.offset < second.element.offset {
          return true
        } else {
          return first.offset < second.offset
        }
      }
      .map { $0.element.element }
  }

  private var sortedErrorsAtOffset: [(offset: Int, error: Error)] = []
}

#endif
