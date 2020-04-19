// Created by George Leontiev on 3/31/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import ResilientDecoding
import XCTest

private struct ResilientOptionalWrapper: Decodable {
  @Resilient var resilientOptional: Int?
}

final class ResilientOptionalTests: XCTestCase {

  func testDecodesValidInputWithoutErrors() throws {
    let mock = try decodeMock(ResilientOptionalWrapper.self, """
      {
        "resilientOptional": 1,
      }
      """)
    XCTAssertEqual(mock.resilientOptional, 1)
    #if DEBUG
    XCTAssert(mock.$resilientOptional.outcome.is(.decodedSuccessfully))
    XCTAssertNil(mock.$resilientOptional.error)
    #endif
  }

  func testDecodesWhenMissingKeyWithoutErrors() throws {
    let mock = try decodeMock(ResilientOptionalWrapper.self, """
      {
      }
      """)
    XCTAssertNil(mock.resilientOptional)
    #if DEBUG
    XCTAssert(mock.$resilientOptional.outcome.is(.keyNotFound))
    XCTAssertNil(mock.$resilientOptional.error)
    #endif
  }

  func testDecodesNullValueWithoutErrors() throws {
    let mock = try decodeMock(ResilientOptionalWrapper.self, """
      {
        "resilientOptional": null
      }
      """)
    XCTAssertNil(mock.resilientOptional)
    #if DEBUG
    XCTAssert(mock.$resilientOptional.outcome.is(.valueWasNil))
    XCTAssertNil(mock.$resilientOptional.error)
    #endif
  }

  func testResilientlyDecodesInvalidValue() throws {
    let mock = try decodeMock(ResilientOptionalWrapper.self, """
      {
        "resilientOptional": "INVALID",
      }
      """,
      expectedErrorCount: 1)
    XCTAssertNil(mock.resilientOptional)
    #if DEBUG
    XCTAssert(mock.$resilientOptional.outcome.is(.recoveredFromError(wasReported: true)))
    XCTAssertNotNil(mock.$resilientOptional.error)
    #endif
  }

}
