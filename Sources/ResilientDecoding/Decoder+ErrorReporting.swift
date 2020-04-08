// Created by George Leontiev on 3/25/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation

// MARK: - Public

extension Dictionary where Key == CodingUserInfoKey, Value == Any {

  /**
   Creates and registers a `ResilientDecodingErrorReporter` with this `userInfo` dictionary. Any `Resilient` properties which are decoded by a `Decoder` with this user info will report their errors to the returned error reporter.
   - note: May only be called once on a particular `userInfo` dictionary
   */
  public mutating func enableResilientDecodingErrorReporting() -> ResilientDecodingErrorReporter {
    if let existingValue = self[resilientDecodingErrorReporterCodingUserInfoKey] {
      assertionFailure()
      if let existingReporter = existingValue as? ResilientDecodingErrorReporter {
        existingReporter.isMissingReportedErrors = true
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

// MARK: - Internal

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

// MARK: - Private

private let resilientDecodingErrorReporterCodingUserInfoKey = CodingUserInfoKey(rawValue: "ResilientDecodingErrorReporter")!
