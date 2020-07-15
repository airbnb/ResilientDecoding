// Created by Suyeol Jeon on 7/16/20.
// Copyright © 2020 Airbnb Inc.

import ResilientDecoding
import XCTest

private struct ResilientObject: Decodable, Equatable {
  @Resilient var resilientValue: Int?
}

final class EquatableTests: XCTestCase {
  func testEqual() {
    XCTAssertEqual(ResilientObject(resilientValue: 10), ResilientObject(resilientValue: 10))
  }

  func testDecodedObjectEqual() throws {
    let decoder = JSONDecoder()
    let decodedObject1 = try decoder.decode(ResilientObject.self, from: #"{"resilientValue": "invalid"}"#.data(using: .utf8)!)
    let decodedObject2 = try decoder.decode(ResilientObject.self, from: #"{"resilientValue": "wrong"}"#.data(using: .utf8)!)
    XCTAssertEqual(decodedObject1, decodedObject2)
  }
}
