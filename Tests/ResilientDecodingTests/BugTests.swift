// Created by George Leontiev on 5/6/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import XCTest
import ResilientDecoding

/**
 Tests for bugs that were encountered after releasing. The commit which introduces a test here should also introduce a fix.
 */
final class BugTests: XCTestCase {

  /**
   This issue was causing this test to fail previously: https://forums.swift.org/t/url-fails-to-decode-when-it-is-a-generic-argument-and-genericargument-from-decoder-is-used/36238
   */
  func testResilientURLsDecodeSuccessfully() throws {
    struct RawRepresentable: ResilientRawRepresentable {
      let rawValue: URL
    }
    struct FrozenRawRepresentable: ResilientRawRepresentable {
      let rawValue: URL
      static var isFrozen: Bool { true }
    }
    struct Mock: Decodable, Sendable {
      @Resilient var optional: URL?
      @Resilient var array: [URL]
      @Resilient var dictionary: [String: URL]
      @Resilient var rawRepresentable: RawRepresentable?
      @Resilient var frozenRawRepresentable: FrozenRawRepresentable?
    }
    let mock = try decodeMock(Mock.self, """
      {
        "optional": "https://www.airbnb.com",
        "array": [
          "https://www.airbnb.com",
          "https://en.wikipedia.org/wiki/Diceware",
        ],
        "dictionary": {
          "Airbnb": "https://www.airbnb.com",
          "Diceware": "https://en.wikipedia.org/wiki/Diceware",
        },
        "rawRepresentable": "https://www.airbnb.com",
        "frozenRawRepresentable": "https://www.airbnb.com",
      }
      """)
    XCTAssertNotNil(mock.optional)
    XCTAssertEqual(mock.array.count, 2)
    XCTAssertEqual(mock.dictionary.count, 2)
    XCTAssertNotNil(mock.rawRepresentable)
    XCTAssertNotNil(mock.frozenRawRepresentable)
    #if DEBUG
    XCTAssertNil(mock.$optional.error)
    XCTAssertNil(mock.$array.error)
    XCTAssertNil(mock.$dictionary.error)
    XCTAssertNil(mock.$rawRepresentable.error)
    XCTAssertNil(mock.$frozenRawRepresentable.error)
    #endif
  }
}
