// Created by George Leontiev on 3/31/20.
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
