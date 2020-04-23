// MIT License
//
// Copyright (c) 2020 Airbnb
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Created by George Leontiev on 4/4/20.

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
    #if DEBUG
    XCTAssertEqual(mock.$resilientArray.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 0)
    XCTAssertEqual(mock.$resilientArrayOfFrozenType.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientArrayOfFrozenType.errors.count, 0)
    #endif
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
    #if DEBUG
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientArrayOfFrozenType.errors.count, 0)
    #endif
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
    #if DEBUG
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientArrayOfFrozenType.errors.count, 0)
    #endif
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

    #if DEBUG
    /// All properties provide errors for inspection, but only _frozen_ types report the error (hence "3" expected errors above)
    XCTAssertEqual(mock.$resilientArray.errors.count, 1)
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 2)
    XCTAssertEqual(mock.$resilientArrayOfFrozenType.errors.count, 1)
    XCTAssertEqual(mock.$optionalResilientArrayOfFrozenType.errors.count, 2)
    #endif
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

    #if DEBUG
    /// All properties provide errors for inspection, but only _frozen_ types report the error (hence "3" expected errors above)
    XCTAssertEqual(mock.$resilientArray.errors.count, 1)
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 2)
    XCTAssertEqual(mock.$resilientArrayOfFrozenType.errors.count, 1)
    XCTAssertEqual(mock.$optionalResilientArrayOfFrozenType.errors.count, 2)
    #endif
  }

}
