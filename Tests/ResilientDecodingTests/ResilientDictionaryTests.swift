// Created by George Leontiev on 4/23/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation

#if DEBUG
@testable import ResilientDecoding
#else
import ResilientDecoding
#endif
import XCTest

private struct ResilientDictionaryWrapper: Decodable {
  @Resilient var resilientDictionary: [String: Int]
  @Resilient var optionalResilientDictionary: [String: Int]?
}

final class DictionaryTests: XCTestCase {

  func testDecodesValidInputWithoutErrors() throws {
    let mock = try decodeMock(ResilientDictionaryWrapper.self, """
      {
        "resilientDictionary": {
          "1": 1,
          "2": 2,
          "3": 3,
        },
        "optionalResilientDictionary": {
          "4": 4,
          "5": 5,
          "6": 6,
        },
      }
      """)
    XCTAssertEqual(mock.resilientDictionary, ["1": 1, "2": 2, "3": 3])
    XCTAssertEqual(mock.optionalResilientDictionary, ["4": 4, "5": 5, "6": 6])
    #if DEBUG
    XCTAssert(mock.$resilientDictionary.outcome.is(.decodedSuccessfully))
    XCTAssert(mock.$optionalResilientDictionary.outcome.is(.decodedSuccessfully))
    XCTAssert(mock.$resilientDictionary.errors.isEmpty)
    XCTAssert(mock.$optionalResilientDictionary.errors.isEmpty)
    #endif
  }

  func testDecodesWhenMissingKeys() throws {
    let mock = try decodeMock(ResilientDictionaryWrapper.self, """
      {
      }
      """)
    XCTAssertEqual(mock.resilientDictionary, [:])
    XCTAssertNil(mock.optionalResilientDictionary)
    #if DEBUG
    XCTAssert(mock.$resilientDictionary.outcome.is(.keyNotFound))
    XCTAssert(mock.$optionalResilientDictionary.outcome.is(.keyNotFound))
    XCTAssertEqual(mock.$resilientDictionary.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientDictionary.errors.count, 0)
    #endif
  }

  func testDecodesNullValue() throws {
    let mock = try decodeMock(ResilientDictionaryWrapper.self, """
      {
        "resilientDictionary": null,
        "optionalResilientDictionary": null,
      }
      """)
    XCTAssertEqual(mock.resilientDictionary, [:])
    XCTAssertNil(mock.optionalResilientDictionary)
    #if DEBUG
    XCTAssert(mock.$resilientDictionary.outcome.is(.valueWasNil))
    XCTAssert(mock.$optionalResilientDictionary.outcome.is(.valueWasNil))
    XCTAssertEqual(mock.$resilientDictionary.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientDictionary.errors.count, 0)
    #endif
  }

  func testResilientlyDecodesIncorrectType() throws {
    let mock = try decodeMock(ResilientDictionaryWrapper.self, """
      {
        "resilientDictionary": 1,
        "optionalResilientDictionary": 1,
      }
      """,
      expectedErrorCount: 2)
    XCTAssertEqual(mock.resilientDictionary, [:])
    XCTAssertEqual(mock.optionalResilientDictionary, [:])
    #if DEBUG
    XCTAssert(mock.$resilientDictionary.outcome.is(.recoveredFromError(wasReported: true)))
    XCTAssertEqual(mock.$resilientDictionary.errors.count, 1)
    XCTAssert(mock.$optionalResilientDictionary.outcome.is(.recoveredFromError(wasReported: true)))
    XCTAssertEqual(mock.$optionalResilientDictionary.errors.count, 1)
    #endif
  }

  func testResilientlyDecodesArrayWithInvalidElements() throws {
    let mock = try decodeMock(ResilientDictionaryWrapper.self, """
      {
        "resilientDictionary": {
          "1": 1,
          "2": "2",
          "3": 3,
          "4": "4",
          "5": 5,
        },
        "optionalResilientDictionary": {
          "1": "1",
          "2": 2,
          "3": "3",
          "4": "4",
          "5": 5,
        },
      }
      """,
      expectedErrorCount: 5)
    XCTAssertEqual(mock.resilientDictionary, ["1": 1, "3": 3, "5": 5])
    XCTAssertEqual(mock.optionalResilientDictionary, ["2": 2, "5": 5])
    #if DEBUG
    XCTAssert(mock.$resilientDictionary.outcome.is(.recoveredFromError(wasReported: false)))
    XCTAssertEqual(mock.$resilientDictionary.errors.count, 2)
    XCTAssertEqual(mock.$resilientDictionary.results.mapValues { try? $0.get() }, ["1": 1, "2": nil, "3": 3, "4": nil, "5": 5])
    XCTAssert(mock.$optionalResilientDictionary.outcome.is(.recoveredFromError(wasReported: false)))
    XCTAssertEqual(mock.$optionalResilientDictionary.errors.count, 3)
    XCTAssertEqual(mock.$optionalResilientDictionary.results.mapValues { try? $0.get() }, ["1": nil, "2": 2, "3": nil, "4": nil, "5": 5])
    #endif
  }

  /**
   This tests internal functionality which decodes a dictionary of results to make sure the coding paths aren't impacted by https://bugs.swift.org/browse/SR-6294
   */
  func testDictionaryOfResults() throws {
    /// `dictionaryOfResults` is internal to `ResilientDecoding` and can only be accessed via a `@testable` import which doesn't work in release.
    #if DEBUG
    let data = """
      {
        "dictionary": {
          "a": "a",
          "b": "b",
          "c": "c"
        }
      }
      """.data(using: .utf8)!
    struct Mock: Swift.Decodable {
      init(from decoder: Decoder) throws {
        let dictionaryDecoder = try decoder.container(keyedBy: CodingKey.self).superDecoder(forKey: .dictionary)
        _ = try dictionaryDecoder.decodeDictionaryOfResults(of: String.self) { decoder in
          let value = try String(from: decoder)
          XCTAssertEqual(decoder.codingPath.map { $0.stringValue }, [CodingKey.dictionary.stringValue, value])
          return value
        }
      }
      private enum CodingKey: String, Swift.CodingKey {
        case dictionary
      }
    }
    _ = try JSONDecoder().decode(Mock.self, from: data)
    #endif
  }

}
