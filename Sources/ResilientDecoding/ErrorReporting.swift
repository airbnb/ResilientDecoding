// Created by George Leontiev on 3/25/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation

// MARK: - Enabling Error Reporting

extension Dictionary where Key == CodingUserInfoKey, Value == Any {

  /**
   Creates and registers a `ResilientDecodingErrorReporter` with this `userInfo` dictionary. Any `Resilient` properties which are decoded by a `Decoder` with this user info will report their errors to the returned error reporter.
   - note: May only be called once on a particular `userInfo` dictionary
   */
  public mutating func enableResilientDecodingErrorReporting() -> ResilientDecodingErrorReporter {
    if let existingValue = self[resilientDecodingErrorReporterCodingUserInfoKey] {
      assertionFailure()
      if let existingReporter = existingValue as? ResilientDecodingErrorReporter {
        existingReporter.currentDigest.mayBeMissingReportedErrors = true
      }
    }
    let errorReporter = ResilientDecodingErrorReporter()
    self[resilientDecodingErrorReporterCodingUserInfoKey] = errorReporter
    return errorReporter
  }

}

extension JSONDecoder {

  /**
   Creates and registers a `ResilientDecodingErrorReporter` with this `JSONDecoder`. Any `Resilient` properties which this `JSONDecoder` decodes will report their errors to the returned error reporter.
   - note: May only be called once per `JSONDecoder`
   */
  public func enableResilientDecodingErrorReporting() -> ResilientDecodingErrorReporter {
    userInfo.enableResilientDecodingErrorReporting()
  }

}

extension Decoder {

  /**
   This method should be called whenever an error is handled by the `Resilient` infrastructure.
   Care should be taken that this is called on the most relevant `Decoder` object, since this method uses the `Decoder`'s `codingPath` to place the error in the correct location in the tree.
   */
  func resilientDecodingHandled(_ error: Swift.Error) {
    guard let errorReporterAny = userInfo[resilientDecodingErrorReporterCodingUserInfoKey] else {
      return
    }
    /**
     Check that we haven't hit the very unlikely case where someone has overriden our user info key with something we do not expect.
     */
    guard let errorReporter = errorReporterAny as? ResilientDecodingErrorReporter else {
      assertionFailure()
      return
    }
    errorReporter.resilientDecodingHandled(error, at: codingPath.map { $0.stringValue })
  }

}

// MARK: - Accessing Reported Errors

public final class ResilientDecodingErrorReporter {

  /**
   This is meant to be called immediately after decoding a `Decodable` type from a `Decoder`.
   - returns: Any errors encountered up to this point in time
   */
  public func flushReportedErrors() -> ErrorDigest? {
    let digest = hasErrors ? currentDigest : nil
    hasErrors = false
    currentDigest = ErrorDigest()
    return digest
  }

  /**
   This should only ever be called by `Decoder.resilientDecodingHandled` when an error is handled, consider calling that method instead.
   It is `internal` and not `fileprivate` only to allow us to split the up the two files.
   */
  func resilientDecodingHandled(_ error: Error, at path: [String]) {
    hasErrors = true
    currentDigest.root.insert(error, at: path)
  }

  fileprivate var currentDigest = ErrorDigest()
  private var hasErrors = false

}

public struct ErrorDigest {

  public var errors: [Error] { errors(includeUnknownNovelValueErrors: false) }

  public func errors(includeUnknownNovelValueErrors: Bool) -> [Error] {
    let allErrors: [Error]
    if mayBeMissingReportedErrors {
      allErrors = [MayBeMissingReportedErrors()] + root.errors
    } else {
      allErrors = root.errors
    }
    return allErrors.filter { includeUnknownNovelValueErrors || !($0 is UnknownNovelValueError) }
  }

  /**
   This should only ever be set from `Decoder.enableResilientDecodingErrorReporting` to signify that reporting has been enabled multiple times and the first `ResilientDecodingErrorReporter` may be missing errors. This behavior is behind an `assert` so it is highly unlikely to happen in production.
   */
  fileprivate var mayBeMissingReportedErrors: Bool = false

  fileprivate struct Node {
    private var children: [String: Node] = [:]
    private var shallowErrors: [Error] = []

    /**
     Inserts an error at the provided path
     */
    mutating func insert<Path: Collection>(_ error: Error, at path: Path)
      where Path.Element == String
    {
      if let next = path.first {
        children[next, default: Node()].insert(error, at: path.dropFirst())
      } else {
        shallowErrors.append(error)
      }
    }

    var errors: [Error] {
      shallowErrors + children.flatMap { $0.value.errors }
    }
  }
  fileprivate var root = Node()

}

// MARK: - Pretty Printing

#if DEBUG

extension ErrorDigest: CustomDebugStringConvertible {
  public var debugDescription: String {
    root.debugDescriptionLines.joined(separator: "\n")
  }
}

extension ErrorDigest.Node {

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

// MARK: - Private

/**
 In the unlikely event that `enableResilientDecodingErrorReporting()` is called multiple times, this error will be reported to the earlier `ResilientDecodingErrorReporter` to signify that the later one may have eaten some of its errors.
 */
private struct MayBeMissingReportedErrors: Error { }

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

private let resilientDecodingErrorReporterCodingUserInfoKey = CodingUserInfoKey(rawValue: "ResilientDecodingErrorReporter")!
