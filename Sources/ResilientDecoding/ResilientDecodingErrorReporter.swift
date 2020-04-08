// Created by George Leontiev on 3/28/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation

// MARK: - Error Reporter

public final class ResilientDecodingErrorReporter {

  /**
   This is meant to be called immediately after decoding a `Decodable` type from a `Decoder`.
   - returns: Any errors encountered up to this point in time
   */
  public func flushReportedErrors(includeUnknownNovelValueErrors: Bool = false) -> [Error] {
    let reportedErrors = errorContainer.errors
    errorContainer = ErrorContainer()
    let errors: [Error]
    if isMissingReportedErrors {
      errors = [IsMissingReportedErrors()] + reportedErrors
    } else {
      errors = reportedErrors
    }
    return errors.filter { includeUnknownNovelValueErrors || !($0 is UnknownNovelValueError) }
  }

  /**
   This should only ever be called by `Decoder.resilientDecodingHandled` when an error is handled, consider calling that method instead.
   It is `internal` and not `fileprivate` only to allow us to split the up the two files.
   */
  func resilientDecodingHandled(_ error: Error, at path: [String]) {
    errorContainer.insert(error, at: path)
  }

  /**
   This should only ever be set from `Decoder.enableResilientDecodingErrorReporting` to signify that reporting has been enabled multiple times and the first `ResilientDecodingErrorReporter` may be missing errors. This behavior is behind an `assert` so it is highly unlikely to happen in production.
   */
  var isMissingReportedErrors: Bool = false

  fileprivate struct ErrorContainer {
    private var children: [String: ErrorContainer] = [:]
    private var shallowErrors: [Error] = []

    /**
     Inserts an error at the provided path
     */
    mutating func insert<Path: Collection>(_ error: Error, at path: Path)
      where Path.Element == String
    {
      if let next = path.first {
        children[next, default: ErrorContainer()].insert(error, at: path.dropFirst())
      } else {
        shallowErrors.append(error)
      }
    }

    var errors: [Error] {
      shallowErrors + children.flatMap { $0.value.errors }
    }
  }

  private var errorContainer = ErrorContainer()

}

// MARK: - Errors

/**
 In the unlikely event that `enableResilientDecodingErrorReporting()` is called multiple times, this error will be reported to the earlier `ResilientDecodingErrorReporter` to signify that the later one may have eaten some of its errors.
 */
private struct IsMissingReportedErrors: Error { }

/**
 An error which is surfaced at the property level but is not reported via `ResilientDecodingErrorReporter` by default (it can still be accessed by providing the `includeUnknownNovelValueErrors: true` argument to `flushReportedErrors`). This error is meant to indicate that the client detected a type it does not understand but believes to be valid, for instance a novel `case` of a `String`-backed `enum`.
 This is primarily used by `ResilientRawRepresentable`, but more complex use-cases exist where it is desirable to suppress error reporting but it would be awkward to implement using `ResilientRawRepresentable`. One such example is a type which inspects a `type` key before deciding how to decode the rest of the data (this pattern is often used to decode `enum`s with associated values). If it is desirable to suppress error reporting when encountering a new `type`, the custom type can explicitly throw this error.
 */
public struct UnknownNovelValueError: Error {

  /**
   The raw value for which `init(rawValue:)` returned `nil`.
   */
  public let novelValue: Any

  /**
   - parameter novelValue: A value which is believed to be valid but the code does not know how to handle.
   */
  public init<T>(novelValue: T) {
    self.novelValue = novelValue
  }

}

// MARK: - Pretty Printing

#if DEBUG

extension ResilientDecodingErrorReporter: CustomDebugStringConvertible {
  public var debugDescription: String {
    errorContainer.debugDescriptionLines.joined(separator: "\n")
  }
}

extension ResilientDecodingErrorReporter.ErrorContainer {

  var debugDescriptionLines: [String] {
    let errorLines = shallowErrors.map { "- " + $0.abridgedDescription }.sorted()
    let childrenLines = children
      .sorted(by: { $0.key < $1.key }).flatMap { child in
        [ child.key ] + child.value.debugDescriptionLines.map { "  " + $0 }
      }
    return errorLines + childrenLines
  }

}

private extension Error {

  /**
   An abridged description which does not include the coding path
   */
  var abridgedDescription: String {
    switch self {
    case let decodingError as DecodingError:
      switch decodingError {
      case .dataCorrupted:
        return "Data corrupted"
      case .keyNotFound(let key, _):
        return "Key \"\(key.stringValue)\" not found"
      case .typeMismatch(let attempted, _):
        return "Could not decode as `\(attempted)`"
      case .valueNotFound(let attempted, _):
        return "Expected `\(attempted)` but found null instead"
      @unknown default:
        return localizedDescription
      }
    case let error as UnknownNovelValueError:
      return "Unknown novel value \"\(error.novelValue)\" (this error is not reported by default)"
    default:
      return localizedDescription
    }
  }

}

#endif
