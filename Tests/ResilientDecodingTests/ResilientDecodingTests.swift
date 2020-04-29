// Created by George Leontiev on 3/24/20.
// Copyright © 2020 Airbnb Inc.

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
    let data = string.data(using: .utf8)!
    let (decoded, errorDigest) = try decoder.decode(T.self, from: data, reportResilientDecodingErrors: true)
    XCTAssertEqual(errorDigest?.errors.count ?? 0, expectedErrorCount)
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
