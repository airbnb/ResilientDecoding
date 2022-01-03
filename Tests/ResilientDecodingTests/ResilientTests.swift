import ResilientDecoding
import XCTest

final class ResilientTests: XCTestCase {
  struct Wrapper: Decodable, Hashable {
    @Resilient var value: ResilientEnumWithFallback
  }

  func testResilientEquatable() throws {
    let json1 = """
      {
          "value": ""
      }
      """.data(using: .utf8)!
    let json2 = """
      {
          "value": "nonexisting"
      }
      """.data(using: .utf8)!

    let decoded1 = try JSONDecoder().decode(Wrapper.self, from: json1)
    let decoded2 = try JSONDecoder().decode(Wrapper.self, from: json2)

    XCTAssertEqual(decoded1, decoded2)
  }

  func testResilientHashable() throws {
    let json1 = """
      {
          "value": ""
      }
      """.data(using: .utf8)!
    let json2 = """
      {
          "value": "nonexisting"
      }
      """.data(using: .utf8)!

    let decoded1 = try JSONDecoder().decode(Wrapper.self, from: json1)
    let decoded2 = try JSONDecoder().decode(Wrapper.self, from: json2)

    XCTAssertEqual(decoded1.hashValue, decoded2.hashValue)
  }
}
