// Created by George Leontiev on 3/31/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import XCTest
import ResilientDecoding

private struct ResilientRawRepresentableEnumWrapper: Decodable {
  @Resilient var resilientEnumWithFallback: ResilientEnumWithFallback
  @Resilient var resilientFrozenEnumWithFallback: ResilientFrozenEnumWithFallback
  @Resilient var optionalResilientEnum: ResilientEnum?
  @Resilient var optionalResilientFrozenEnum: ResilientFrozenEnum?
  @Resilient var optionalResilientEnumWithFallback: ResilientEnumWithFallback?
  @Resilient var optionalResilientFrozenEnumWithFallback: ResilientFrozenEnumWithFallback?
}

final class ResilientRawRepresentableEnumTests: XCTestCase {

  func testDecodesValidCasesWithoutErrors() throws {
    let mock = try decodeMock(ResilientRawRepresentableEnumWrapper.self, """
      {
        "resilientEnumWithFallback": "existing",
        "resilientFrozenEnumWithFallback": "existing",
        "optionalResilientEnum": "existing",
        "optionalResilientFrozenEnum": "existing",
        "optionalResilientEnumWithFallback": "existing",
        "optionalResilientFrozenEnumWithFallback": "existing",
      }
      """)
    XCTAssertEqual(mock.resilientEnumWithFallback, .existing)
    XCTAssertEqual(mock.resilientFrozenEnumWithFallback, .existing)
    XCTAssertEqual(mock.optionalResilientEnum, .existing)
    XCTAssertEqual(mock.optionalResilientFrozenEnum, .existing)
    XCTAssertEqual(mock.optionalResilientEnumWithFallback, .existing)
    XCTAssertEqual(mock.optionalResilientFrozenEnumWithFallback, .existing)
    #if DEBUG
    XCTAssertNil(mock.$resilientEnumWithFallback.error)
    XCTAssertNil(mock.$resilientFrozenEnumWithFallback.error)
    XCTAssertNil(mock.$optionalResilientEnum.error)
    XCTAssertNil(mock.$optionalResilientFrozenEnum.error)
    XCTAssertNil(mock.$optionalResilientEnumWithFallback.error)
    XCTAssertNil(mock.$optionalResilientFrozenEnumWithFallback.error)
    #endif
  }

  func testDecodesNullOptionalValuesWithoutErrors() throws {
    let mock = try decodeMock(ResilientRawRepresentableEnumWrapper.self, """
      {
        "resilientEnumWithFallback": "existing",
        "resilientFrozenEnumWithFallback": "existing",
        "optionalResilientEnum": null,
        "optionalResilientFrozenEnum": null,
        "optionalResilientEnumWithFallback": null,
        "optionalResilientFrozenEnumWithFallback": null,
      }
      """)
    XCTAssertNil(mock.optionalResilientEnum)
    XCTAssertNil(mock.optionalResilientFrozenEnum)
    XCTAssertNil(mock.optionalResilientEnumWithFallback)
    XCTAssertNil(mock.optionalResilientFrozenEnumWithFallback)
    #if DEBUG
    XCTAssertNil(mock.$optionalResilientEnum.error)
    XCTAssertNil(mock.$optionalResilientFrozenEnum.error)
    XCTAssertNil(mock.$optionalResilientEnumWithFallback.error)
    XCTAssertNil(mock.$optionalResilientFrozenEnumWithFallback.error)
    #endif
  }

  func testDecodesMissingOptionalValuesWithoutErrors() throws {
    let mock = try decodeMock(ResilientRawRepresentableEnumWrapper.self, """
      {
        "resilientEnumWithFallback": "existing",
        "resilientFrozenEnumWithFallback": "existing",
      }
      """)
    XCTAssertNil(mock.optionalResilientEnum)
    XCTAssertNil(mock.optionalResilientFrozenEnum)
    XCTAssertNil(mock.optionalResilientEnumWithFallback)
    XCTAssertNil(mock.optionalResilientFrozenEnumWithFallback)
    #if DEBUG
    XCTAssertNil(mock.$optionalResilientEnum.error)
    XCTAssertNil(mock.$optionalResilientFrozenEnum.error)
    XCTAssertNil(mock.$optionalResilientEnumWithFallback.error)
    XCTAssertNil(mock.$optionalResilientFrozenEnumWithFallback.error)
    #endif
  }

  func testResilientlyDecodesMissingValues() throws {
    let mock = try decodeMock(ResilientRawRepresentableEnumWrapper.self, """
      {
      }
      """,
      expectedErrorCount: 2)
    XCTAssertEqual(mock.resilientEnumWithFallback, .unknown)
    XCTAssertEqual(mock.resilientFrozenEnumWithFallback, .unknown)
    #if DEBUG
    XCTAssertNotNil(mock.$resilientEnumWithFallback.error)
    XCTAssertNotNil(mock.$resilientFrozenEnumWithFallback.error)
    #endif
  }

  func testResilientlyDecodesNovelCases() throws {
    let mock = try decodeMock(ResilientRawRepresentableEnumWrapper.self, """
      {
        "resilientEnumWithFallback": "novel",
        "resilientFrozenEnumWithFallback": "novel",
        "optionalResilientEnum": "novel",
        "optionalResilientFrozenEnum": "novel",
        "optionalResilientEnumWithFallback": "novel",
        "optionalResilientFrozenEnumWithFallback": "novel",
      }
      """,
      expectedErrorCount: 3)
    XCTAssertEqual(mock.resilientEnumWithFallback, .unknown)
    XCTAssertEqual(mock.resilientFrozenEnumWithFallback, .unknown)
    XCTAssertNil(mock.optionalResilientEnum)
    XCTAssertNil(mock.optionalResilientFrozenEnum)
    XCTAssertEqual(mock.optionalResilientEnumWithFallback, .unknown)
    XCTAssertEqual(mock.optionalResilientFrozenEnumWithFallback, .unknown)
    
    #if DEBUG
    /// All properties provide an error for inspection, but only _frozen_ types report the error (hence "3" expected errors above)
    XCTAssertNotNil(mock.$resilientEnumWithFallback.error)
    XCTAssertNotNil(mock.$resilientFrozenEnumWithFallback.error)
    XCTAssertNotNil(mock.$optionalResilientEnum.error)
    XCTAssertNotNil(mock.$optionalResilientFrozenEnum.error)
    XCTAssertNotNil(mock.$optionalResilientEnumWithFallback.error)
    XCTAssertNotNil(mock.$optionalResilientFrozenEnumWithFallback.error)
    #endif
  }

  func testResilientlyDecodesInvalidCases() throws {
    let mock = try decodeMock(ResilientRawRepresentableEnumWrapper.self, """
      {
        "resilientEnumWithFallback": 1,
        "resilientFrozenEnumWithFallback": 2,
        "optionalResilientEnum": 3,
        "optionalResilientFrozenEnum": 4,
        "optionalResilientEnumWithFallback": 5,
        "optionalResilientFrozenEnumWithFallback": 6,
      }
      """,
      expectedErrorCount: 6)
    XCTAssertEqual(mock.resilientEnumWithFallback, .unknown)
    XCTAssertEqual(mock.resilientFrozenEnumWithFallback, .unknown)
    XCTAssertNil(mock.optionalResilientEnum)
    XCTAssertNil(mock.optionalResilientFrozenEnum)
    XCTAssertEqual(mock.optionalResilientEnumWithFallback, .unknown)
    XCTAssertEqual(mock.optionalResilientFrozenEnumWithFallback, .unknown)
    
    #if DEBUG
    /// Because this is invalid input and not a novel case, errors are provided at the property level _and_ reported (hence "6" expected errors above)
    XCTAssertNotNil(mock.$resilientEnumWithFallback.error)
    XCTAssertNotNil(mock.$resilientFrozenEnumWithFallback.error)
    XCTAssertNotNil(mock.$optionalResilientEnum.error)
    XCTAssertNotNil(mock.$optionalResilientFrozenEnum.error)
    XCTAssertNotNil(mock.$optionalResilientEnumWithFallback.error)
    XCTAssertNotNil(mock.$optionalResilientFrozenEnumWithFallback.error)
    #endif
  }

}
