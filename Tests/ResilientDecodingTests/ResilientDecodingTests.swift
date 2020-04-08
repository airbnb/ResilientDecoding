// Created by George Leontiev on 3/24/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import ResilientDecoding
import XCTest

enum ResilientEnum: String, ResilientRawRepresentable {
  case existing
  case unknown
}

enum ResilientEnumWithFallback: String, ResilientRawRepresentable {
  case existing
  case unknown
  static var decodingFallback: Self { .unknown }
}

enum ResilientFrozenEnum: String, ResilientRawRepresentable {
  case existing
  case unknown
  static var isFrozen: Bool { true }
}

enum ResilientFrozenEnumWithFallback: String, ResilientRawRepresentable {
  case existing
  case unknown
  static var isFrozen: Bool { true }
  static var decodingFallback: Self { .unknown }
}

extension XCTestCase {

  func decodeMock<T: Decodable>(_ type: T.Type, _ string: String, expectedErrorCount: Int = 0) throws -> T {
    let decoder = JSONDecoder()
    let errorReporter = decoder.enableResilientDecodingErrorReporting()
    let decoded = try decoder.decode(T.self, from: string.data(using: .utf8)!)
    let errors = errorReporter.flushReportedErrors()
    XCTAssertEqual(errors.count, expectedErrorCount)
    // Ensure that errors were actually flushed
    XCTAssertEqual(errorReporter.flushReportedErrors().count, 0)
    return decoded
  }

}
