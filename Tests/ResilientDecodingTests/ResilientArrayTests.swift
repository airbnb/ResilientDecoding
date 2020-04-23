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

// Created by George Leontiev on 3/31/20.

import ResilientDecoding
import XCTest

private struct ResilientArrayWrapper: Decodable {
  @Resilient var resilientArray: [Int]
  @Resilient var optionalResilientArray: [Int]?
}

final class ResilientArrayTests: XCTestCase {

  func testDecodesValidInputWithoutErrors() throws {
    let mock = try decodeMock(ResilientArrayWrapper.self, """
      {
        "resilientArray": [1, 2, 3],
        "optionalResilientArray": [4, 5, 6],
      }
      """)
    XCTAssertEqual(mock.resilientArray, [1, 2, 3])
    XCTAssertEqual(mock.optionalResilientArray, [4, 5, 6])
    #if DEBUG
    XCTAssert(mock.$resilientArray.outcome.is(.decodedSuccessfully))
    XCTAssert(mock.$optionalResilientArray.outcome.is(.decodedSuccessfully))
    XCTAssert(mock.$resilientArray.errors.isEmpty)
    XCTAssert(mock.$optionalResilientArray.errors.isEmpty)
    #endif
  }

  func testDecodesWhenMissingKeys() throws {
    let mock = try decodeMock(ResilientArrayWrapper.self, """
      {
      }
      """)
    XCTAssertEqual(mock.resilientArray, [])
    XCTAssertNil(mock.optionalResilientArray)
    #if DEBUG
    XCTAssert(mock.$resilientArray.outcome.is(.keyNotFound))
    XCTAssert(mock.$optionalResilientArray.outcome.is(.keyNotFound))
    XCTAssertEqual(mock.$resilientArray.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 0)
    #endif
  }

  func testDecodesNullValue() throws {
    let mock = try decodeMock(ResilientArrayWrapper.self, """
      {
        "resilientArray": null,
        "optionalResilientArray": null,
      }
      """)
    XCTAssertEqual(mock.resilientArray, [])
    XCTAssertNil(mock.optionalResilientArray)
    #if DEBUG
    XCTAssert(mock.$resilientArray.outcome.is(.valueWasNil))
    XCTAssert(mock.$optionalResilientArray.outcome.is(.valueWasNil))
    XCTAssertEqual(mock.$resilientArray.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 0)
    #endif
  }

  func testResilientlyDecodesIncorrectType() throws {
    let mock = try decodeMock(ResilientArrayWrapper.self, """
      {
        "resilientArray": 1,
        "optionalResilientArray": 1,
      }
      """,
      expectedErrorCount: 2)
    XCTAssertEqual(mock.resilientArray, [])
    XCTAssertEqual(mock.optionalResilientArray, [])
    #if DEBUG
    XCTAssert(mock.$resilientArray.outcome.is(.recoveredFromError(wasReported: true)))
    XCTAssertEqual(mock.$resilientArray.errors.count, 1)
    XCTAssertEqual(mock.$resilientArray.results.map { try? $0.get() }, [nil])
    XCTAssert(mock.$optionalResilientArray.outcome.is(.recoveredFromError(wasReported: true)))
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 1)
    XCTAssertEqual(mock.$optionalResilientArray.results.map { try? $0.get() }, [nil])
    #endif
  }

  func testResilientlyDecodesArrayWithInvalidElements() throws {
    let mock = try decodeMock(ResilientArrayWrapper.self, """
      {
        "resilientArray": [1, "2", 3, "4", 5],
        "optionalResilientArray": ["1", 2, "3", "4", 5],
      }
      """,
      expectedErrorCount: 5)
    XCTAssertEqual(mock.resilientArray, [1, 3, 5])
    XCTAssertEqual(mock.optionalResilientArray, [2, 5])
    #if DEBUG
    XCTAssert(mock.$resilientArray.outcome.is(.recoveredFromError(wasReported: false)))
    XCTAssertEqual(mock.$resilientArray.errors.count, 2)
    XCTAssertEqual(mock.$resilientArray.results.map { try? $0.get() }, [1, nil, 3, nil, 5])
    XCTAssert(mock.$optionalResilientArray.outcome.is(.recoveredFromError(wasReported: false)))
    XCTAssertEqual(mock.$optionalResilientArray.errors.count, 3)
    XCTAssertEqual(mock.$optionalResilientArray.results.map { try? $0.get() }, [nil, 2, nil, nil, 5])
    #endif
  }

}
