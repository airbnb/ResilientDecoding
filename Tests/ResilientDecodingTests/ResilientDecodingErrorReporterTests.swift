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

// Created by George Leontiev on 4/2/20.

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
    #if DEBUG
    XCTAssertEqual(errorReporter.debugDescription, """
      resilientArray
        Index 1
          - Could not decode as `Int`
        Index 3
          - Could not decode as `Int`
      resilientEnum
        - Unknown novel value "novel" (this error is not reported by default)
      """)
    #endif
  }

}
