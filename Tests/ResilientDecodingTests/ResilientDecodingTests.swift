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

// Created by George Leontiev on 3/24/20.

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

#if DEBUG
/**
 Since `Error` is not `Equatable`, we use this `enum` to verify the correct outcome was encountered
 */
enum ExpectedDecodingOutcome {
  case decodedSuccessfully
  case keyNotFound
  case valueWasNil
  case recoveredFromError(wasReported: Bool)
}

extension ResilientDecodingOutcome {
  func `is`(_ expected: ExpectedDecodingOutcome) -> Bool {
    switch (self, expected) {
    case
      (.decodedSuccessfully, .decodedSuccessfully),
      (.keyNotFound, .keyNotFound),
      (.valueWasNil, .valueWasNil):
        return true
    case let (.recoveredFrom(_, lhs), .recoveredFromError(rhs)):
      return lhs == rhs
    default:
      return false
    }
  }
}
#endif
