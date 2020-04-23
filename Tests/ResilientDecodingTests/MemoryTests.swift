// Created by George Leontiev on 4/2/20.
// Copyright © 2020 Airbnb Inc.

import ResilientDecoding
import XCTest

final class MemoryTests: XCTestCase {
  func testNoOverheadInRelease() throws {
    #if !DEBUG
    struct StandardProperties {
      let foo: String
      let bar: Int
    }
    struct ResilientProperties {
      @Resilient var foo: String
      @Resilient var bar: Int
    }
    XCTAssertEqual(MemoryLayout<StandardProperties>.size, MemoryLayout<ResilientProperties>.size)
    #endif
  }
}
