// Created by George Leontiev on 4/23/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import ResilientDecoding
import XCTest

private struct ResilientRawRepresentableDictionaryWrapper: Decodable {
  @Resilient var resilientDictionary: [String: ResilientEnum]
  @Resilient var optionalResilientDictionary: [String: ResilientEnum]?
  @Resilient var resilientDictionaryOfFrozenType: [String: ResilientFrozenEnum]
  @Resilient var optionalResilientDictionaryOfFrozenType: [String: ResilientFrozenEnum]?
}

final class ResilientRawRepresentableDictionaryTests: XCTestCase {

  func testDecodesValidInputWithoutErrors() throws {
    let mock = try decodeMock(ResilientRawRepresentableDictionaryWrapper.self, """
      {
        "resilientDictionary": { "1": "existing", "2": "existing" },
        "optionalResilientDictionary": { "1": "existing", "2": "existing" },
        "resilientDictionaryOfFrozenType": { "1": "existing", "2": "existing" },
        "optionalResilientDictionaryOfFrozenType": { "1": "existing", "2": "existing" },
      }
      """)
    XCTAssertEqual(mock.resilientDictionary, ["1": .existing, "2": .existing])
    XCTAssertEqual(mock.optionalResilientDictionary, ["1": .existing, "2": .existing])
    XCTAssertEqual(mock.resilientDictionaryOfFrozenType, ["1": .existing, "2": .existing])
    XCTAssertEqual(mock.optionalResilientDictionaryOfFrozenType, ["1": .existing, "2": .existing])
    #if DEBUG
    XCTAssertEqual(mock.$resilientDictionary.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientDictionary.errors.count, 0)
    XCTAssertEqual(mock.$resilientDictionaryOfFrozenType.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientDictionaryOfFrozenType.errors.count, 0)
    #endif
  }

  /**
   - note: We keep the non-optional properties in the JSON so they do not report errors
   */
  func testDecodesWhenMissingKeysWithoutErrors() throws {
    let mock = try decodeMock(ResilientRawRepresentableDictionaryWrapper.self, """
      {
        "resilientDictionary": { "1": "existing", "2": "existing" },
        "resilientDictionaryOfFrozenType": { "1": "existing", "2": "existing" },
      }
      """)
    XCTAssertEqual(mock.optionalResilientDictionary, nil)
    XCTAssertEqual(mock.optionalResilientDictionaryOfFrozenType, nil)
    #if DEBUG
    XCTAssertEqual(mock.$optionalResilientDictionary.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientDictionaryOfFrozenType.errors.count, 0)
    #endif
  }
  
  /**
   - note: We keep the non-optional properties in the JSON so they do not report errors
   */
  func testDecodesNullValuesWithoutErrors() throws {
    let mock = try decodeMock(ResilientRawRepresentableDictionaryWrapper.self, """
      {
        "resilientDictionary": { "1": "existing", "2": "existing" },
        "optionalResilientDictionary": null,
        "resilientDictionaryOfFrozenType": { "1": "existing", "2": "existing" },
        "optionalResilientDictionaryOfFrozenType": null,
      }
      """)
    XCTAssertEqual(mock.optionalResilientDictionary, nil)
    XCTAssertEqual(mock.optionalResilientDictionaryOfFrozenType, nil)
    #if DEBUG
    XCTAssertEqual(mock.$optionalResilientDictionary.errors.count, 0)
    XCTAssertEqual(mock.$optionalResilientDictionaryOfFrozenType.errors.count, 0)
    #endif
  }

  func testResilientlyDecodesNovelCases() throws {
    let mock = try decodeMock(ResilientRawRepresentableDictionaryWrapper.self, """
      {
        "resilientDictionary": {
          "1": "existing",
          "2": "novel",
          "3": "existing",
        },
        "optionalResilientDictionary": {
          "1": "novel",
          "2": "existing",
          "3": "novel",
        },
        "resilientDictionaryOfFrozenType": {
          "1": "existing",
          "2": "novel",
          "3": "existing",
        },
        "optionalResilientDictionaryOfFrozenType": {
          "1": "novel",
          "2": "existing",
          "3": "novel",
        },
      }
      """,
      expectedErrorCount: 3)
    XCTAssertEqual(mock.resilientDictionary, ["1": .existing, "3": .existing])
    XCTAssertEqual(mock.optionalResilientDictionary, ["2": .existing])
    XCTAssertEqual(mock.resilientDictionaryOfFrozenType, ["1": .existing, "3": .existing])
    XCTAssertEqual(mock.optionalResilientDictionaryOfFrozenType, ["2": .existing])

    #if DEBUG
    /// All properties provide errors for inspection, but only _frozen_ types report the error (hence "3" expected errors above)
    XCTAssertEqual(mock.$resilientDictionary.errors.count, 1)
    XCTAssertEqual(mock.$optionalResilientDictionary.errors.count, 2)
    XCTAssertEqual(mock.$resilientDictionaryOfFrozenType.errors.count, 1)
    XCTAssertEqual(mock.$optionalResilientDictionaryOfFrozenType.errors.count, 2)
    #endif
  }

  func testResilientlyDecodesInvalidCases() throws {
    let mock = try decodeMock(ResilientRawRepresentableDictionaryWrapper.self, """
      {
        "resilientDictionary": {
          "1": "existing",
          "2": 2,
          "3": "existing",
        },
        "optionalResilientDictionary": {
          "1": 1,
          "2": "existing",
          "3": 3,
        },
        "resilientDictionaryOfFrozenType": {
          "1": "existing",
          "2": 2,
          "3": "existing",
        },
        "optionalResilientDictionaryOfFrozenType": {
          "1": 1,
          "2": "existing",
          "3": 3,
        },
      }
      """,
      expectedErrorCount: 6)
    XCTAssertEqual(mock.resilientDictionary, ["1": .existing, "3": .existing])
    XCTAssertEqual(mock.optionalResilientDictionary, ["2": .existing])
    XCTAssertEqual(mock.resilientDictionaryOfFrozenType, ["1": .existing, "3": .existing])
    XCTAssertEqual(mock.optionalResilientDictionaryOfFrozenType, ["2": .existing])

    #if DEBUG
    /// All properties provide errors for inspection, but only _frozen_ types report the error (hence "6" expected errors above)
    XCTAssertEqual(mock.$resilientDictionary.errors.count, 1)
    XCTAssertEqual(mock.$optionalResilientDictionary.errors.count, 2)
    XCTAssertEqual(mock.$resilientDictionaryOfFrozenType.errors.count, 1)
    XCTAssertEqual(mock.$optionalResilientDictionaryOfFrozenType.errors.count, 2)
    #endif
  }

  /**
   When a `Dictionary` is decoded, the keys are not transformed by the `keyDecodingStrategy`.
   */
  func testKeyDecodingStrategyIsIgnored() throws {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    struct Mock: Decodable {
      @Resilient var resilientDictionary: [String: Int]
    }
    let mock = try decoder.decode(Mock.self, from: """
      {
        "resilient_dictionary": {
          "the_number_one": 1,
          "the_number_two": 2,
          "the_number_three": 3,
        }
      }
      """.data(using: .utf8)!)
    XCTAssertEqual(mock.resilientDictionary, [
      "the_number_one": 1,
      "the_number_two": 2,
      "the_number_three": 3
    ])
  }

}
