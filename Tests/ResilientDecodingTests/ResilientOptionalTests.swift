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
    XCTAssertNil(mock.$resilientOptional.error)
  }

  func testDecodesWhenMissingKeyWithoutErrors() throws {
    let mock = try decodeMock(ResilientOptionalWrapper.self, """
      {
      }
      """)
    XCTAssertNil(mock.resilientOptional)
    XCTAssertNil(mock.$resilientOptional.error)
  }

  func testDecodesNullValueWithoutErrors() throws {
    let mock = try decodeMock(ResilientOptionalWrapper.self, """
      {
        "resilientOptional": null
      }
      """)
    XCTAssertNil(mock.resilientOptional)
    XCTAssertNil(mock.$resilientOptional.error)
  }

  func testResilientlyDecodesInvalidValue() throws {
    let mock = try decodeMock(ResilientOptionalWrapper.self, """
      {
        "resilientOptional": "INVALID",
      }
      """,
      expectedErrorCount: 1)
    XCTAssertNil(mock.resilientOptional)
    XCTAssertNotNil(mock.$resilientOptional.error)
  }

}
