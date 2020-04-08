// Created by George Leontiev on 4/4/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import ResilientDecoding
import XCTest

private struct ResilientRawRepresentableArrayWrapper: Decodable {
  @Resilient var resilientArray: [ResilientEnum]
  @Resilient var optionalResilientArray: [ResilientEnum]?
  @Resilient var resilientArrayOfFrozenType: [ResilientFrozenEnum]
  @Resilient var optionalResilientArrayOfFrozenType: [ResilientFrozenEnum]?
}

final class ResilientRawRepresentableArrayTests: XCTestCase {

  func testDecodesValidInputWithoutErrors() throws {
    let mock = try decodeMock(ResilientRawRepresentableArrayWrapper.self, """
      {
        "resilientArray": ["existing", "existing"],
        "optionalResilientArray": ["existing", "existing"],
        "resilientArrayOfFrozenType": ["existing", "existing"],
        "optionalResilientArrayOfFrozenType": ["existing", "existing"],
      }
      """)
    XCTAssertEqual(mock.resilientArray, [.existing, .existing])
    XCTAssertEqual(mock.optionalResilientArray, [.existing, .existing])
    XCTAssertEqual(mock.resilientArrayOfFrozenType, [.existing, .existing])
    XCTAssertEqual(mock.optionalResilientArrayOfFrozenType, [.existing, .existing])
    XCTAssertEqual(mock.$resilientArray.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 0)
    XCTAssertEqual(mock.$resilientArrayOfFrozenType.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientArrayOfFrozenType.errors.count, 0)
  }

  func testDecodesWhenMissingKeysWithoutErrors() throws {
    let mock = try decodeMock(ResilientRawRepresentableArrayWrapper.self, """
      {
        "resilientArray": ["existing", "existing"],
        "resilientArrayOfFrozenType": ["existing", "existing"],
      }
      """)
    XCTAssertEqual(mock.optionalResilientArray, nil)
    XCTAssertEqual(mock.optionalResilientArrayOfFrozenType, nil)
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientArrayOfFrozenType.errors.count, 0)
  }

  func testDecodesNullValuesWithoutErrors() throws {
    let mock = try decodeMock(ResilientRawRepresentableArrayWrapper.self, """
      {
        "resilientArray": ["existing", "existing"],
        "optionalResilientArray": null,
        "resilientArrayOfFrozenType": ["existing", "existing"],
        "optionalResilientArrayOfFrozenType": null,
      }
      """)
    XCTAssertEqual(mock.optionalResilientArray, nil)
    XCTAssertEqual(mock.optionalResilientArrayOfFrozenType, nil)
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientArrayOfFrozenType.errors.count, 0)
  }

  func testResilientlyDecodesNovelCases() throws {
    let mock = try decodeMock(ResilientRawRepresentableArrayWrapper.self, """
      {
        "resilientArray": ["existing", "novel", "existing"],
        "optionalResilientArray": ["novel", "existing", "novel"],
        "resilientArrayOfFrozenType": ["existing", "novel", "existing"],
        "optionalResilientArrayOfFrozenType": ["novel", "existing", "novel"],
      }
      """,
      expectedErrorCount: 3)
    XCTAssertEqual(mock.resilientArray, [.existing, .existing])
    XCTAssertEqual(mock.optionalResilientArray, [.existing])
    XCTAssertEqual(mock.resilientArrayOfFrozenType, [.existing, .existing])
    XCTAssertEqual(mock.optionalResilientArrayOfFrozenType, [.existing])

    /// All properties provide errors for inspection, but only _frozen_ types report the error (hence "3" expected errors above)
    XCTAssertEqual(mock.$resilientArray.errors.count, 1)
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 2)
    XCTAssertEqual(mock.$resilientArrayOfFrozenType.errors.count, 1)
    XCTAssertEqual(mock.$optionalResilientArrayOfFrozenType.errors.count, 2)
  }

  func testResilientlyDecodesInvalidCases() throws {
    let mock = try decodeMock(ResilientRawRepresentableArrayWrapper.self, """
      {
        "resilientArray": ["existing", 1, "existing"],
        "optionalResilientArray": [2, "existing", 3],
        "resilientArrayOfFrozenType": ["existing", 4, "existing"],
        "optionalResilientArrayOfFrozenType": [5, "existing", 6],
      }
      """,
      expectedErrorCount: 6)
    XCTAssertEqual(mock.resilientArray, [.existing, .existing])
    XCTAssertEqual(mock.optionalResilientArray, [.existing])
    XCTAssertEqual(mock.resilientArrayOfFrozenType, [.existing, .existing])
    XCTAssertEqual(mock.optionalResilientArrayOfFrozenType, [.existing])

    /// All properties provide errors for inspection, but only _frozen_ types report the error (hence "3" expected errors above)
    XCTAssertEqual(mock.$resilientArray.errors.count, 1)
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 2)
    XCTAssertEqual(mock.$resilientArrayOfFrozenType.errors.count, 1)
    XCTAssertEqual(mock.$optionalResilientArrayOfFrozenType.errors.count, 2)
  }

}
