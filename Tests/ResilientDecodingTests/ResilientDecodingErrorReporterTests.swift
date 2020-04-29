// Created by George Leontiev on 4/2/20.
// Copyright © 2020 Airbnb Inc.

import ResilientDecoding
import XCTest

private struct ResilientArrayWrapper: Decodable {
  @Resilient var resilientArray: [Int]
  @Resilient var resilientEnum: ResilientEnum?
}

final class ResilientDecodingErrorReporterTests: XCTestCase {

  func testDebugDescription() throws {
    let decoder = JSONDecoder()
    let errorReporter = decoder.enableResilientDecodingErrorReporting()
    _ = try decoder.decode(ResilientArrayWrapper.self, from: """
      {
        "resilientArray": [1, "2", 3, "4", 5],
        "resilientEnum": "novel",
      }
      """.data(using: .utf8)!)
    guard let errorDigest = errorReporter.flushReportedErrors() else {
      XCTFail()
      return
    }
    #if DEBUG
    XCTAssertEqual(errorDigest.debugDescription, """
      resilientArray
        Index 1
          - Could not decode as `Int`
        Index 3
          - Could not decode as `Int`
      resilientEnum
        - Unknown novel value "novel" (this error is not reported by default)
      """)
    #endif
    // Ensure that the error digest was actually flushed
    XCTAssertNil(errorReporter.flushReportedErrors())
  }

}
