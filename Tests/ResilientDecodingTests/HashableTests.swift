// Created by Suyeol Jeon on 7/16/20.
// Copyright © 2020 Airbnb Inc.

import ResilientDecoding
import XCTest

private struct ResilientObject: Decodable, Hashable {
  @Resilient var resilientValue: Int?
}

final class HashableTests: XCTestCase {
  func testHashable() {
    XCTAssertEqual(ResilientObject(resilientValue: 10).hashValue, ResilientObject(resilientValue: 10).hashValue)
  }

  func testDecodedObjectHashable() throws {
    let decoder = JSONDecoder()
    let decodedObject1 = try decoder.decode(ResilientObject.self, from: #"{"resilientValue": "invalid"}"#.data(using: .utf8)!)
    let decodedObject2 = try decoder.decode(ResilientObject.self, from: #"{"resilientValue": "wrong"}"#.data(using: .utf8)!)
    XCTAssertEqual(decodedObject1.hashValue, decodedObject2.hashValue)
  }
}
