// Created by George Leontiev on 4/3/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation

/**
 The `Resilient` property wrapper has a `projectedValue` in `DEBUG` builds which contains the error(s) encountered when decoding that property. This is intended to only be used during development, error reporting in release should instead be done via `ResilientDecodingErrorReporter`.
 Limiting this functionality to `DEBUG` allows us to trade some extra complexity in this file for better _clarity at point of use_ (https://swift.org/documentation/api-design-guidelines/) and guarantee that this doesn't impact release builds.
 */
#if DEBUG

// MARK: - Optional

extension Resilient.ProjectedValue where Value: ExpressibleByNilLiteral {

  /**
   Returns an error if one was encountered during decoding
   */
  public var error: Error? {
    topLevelError
  }

}

// MARK: - Resiliently Decodable

extension Resilient.ProjectedValue where Value: ResilientRawRepresentable {

  /**
   Returns an error if one was encountered during decoding
   */
  public var error: Error? {
    topLevelError
  }

}

// MARK: - Sequences

extension Resilient.ProjectedValue where Value: _ResilientSequence {

  /**
   All errors encountered during decoding
   */
  public var errors: [Error] { _errors }

  /**
   Interleaves encountered errors with the provided set of elements, potentially returning a single error in the case that the top-level decoding has failed.
   */
  public var results: [Result<Value._Element, Error>] { _errors(interleavedWith: value._resilientElements) }

}

extension Resilient.ProjectedValue where Value: Sequence {

  /**
   All errors encountered during decoding
   */
  public var errors: [Error] { _errors }

  /**
   Interleaves encountered errors with the provided set of elements, potentially returning a single error in the case that the top-level decoding has failed.
   */
  public var results: [Result<Value.Element, Error>] { _errors(interleavedWith: value) }

}

extension Resilient.ProjectedValue {

  /**
   Returns all errors encountered during decoding
   */
  private var _errors: [Error] {
    let offsetErrors = errorsAtOffset.map { $0.error }
    if let error = topLevelError {
      return [error] + offsetErrors
    } else {
      return offsetErrors
    }
  }

  /**
   Interleaves encountered errors with the provided set of elements, potentially returning a single error in the case that the top-level decoding has failed.
   */
  private func _errors<Value: Sequence>(interleavedWith value: Value) -> [Result<Value.Element, Error>] {
    if let error = topLevelError {
      /// The top-level decoding failed
      return [.failure(error)]
    }

    /**
     `errorsAtOffset` are in the order the error was encountered, with the offset being the index where a successsfully decoded element would have been inserted. As a result, consecutive errors have the same offset as the subsequent successfully parsed element. We can thus recreate the original ordering by stably sorting an array of all errors followed by all values by their offset (a stable sort is a sort where the relative ordering of equal elements is preserved).
     */
    typealias ResultAtOffset = (offset: Int, element: Result<Value.Element, Error>)
    let resultsAtOffset: [ResultAtOffset] =
      errorsAtOffset.map { (offset: $0.offset, element: .failure($0.error)) }
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

}

// MARK: - Implementation Details

/**
 I generally avoid underscoring things, but this is `DEBUG`-only and if we are polluting `Optional` below, I prefer having an underscore to indicate that this protocol and its property should not be used by consumers.
 A `Resilient` type representing a sequence, this protocol is used to surface sequence-specific error properties on `Resilient.ProjectedValue`.
 */
public protocol _ResilientSequence {
  associatedtype _Element
  var _resilientElements: [_Element] { get }
}

/**
 I generally avoid extensions on standard types but this one is `DEBUG`-only.
 This is the only way I know to write essentially `extension Resilient<[T]?>.ProjectedValue` (as `extension Resilient.ProjectedValue where Value: ResilientSequence`).
 */
extension Optional: _ResilientSequence where Wrapped: Sequence & ExpressibleByArrayLiteral {
  public var _resilientElements: [Wrapped.Element] { Array(self ?? []) }
}

/**
 An error encountered while decoding a `Resilient` array and the offset it was encountered at
 */
struct ErrorAtOffset {
  let offset: Int
  let error: Error
}

#endif
