import XCTest
@testable import Smittestopp

class JSONDateDecodingTests: XCTestCase {
    struct Bazinga: Codable {
        let date: Date
    }

    let decoder = JSONDecoder.standard

    func testDateWithMilliseconds() {
        let input = """
        {
          "date": "2020-01-27T17:02:10.123Z"
        }
        """.data(using: .utf8)!

        let result = try! decoder.decode(Bazinga.self, from: input)
        XCTAssertEqual(result.date.description, "2020-01-27 17:02:10 +0000")
    }

    func testDateWithMillisecondsAndTimezone() {
        let input = """
        {
          "date": "2020-01-27T17:02:10.123+0100"
        }
        """.data(using: .utf8)!

        let result = try! decoder.decode(Bazinga.self, from: input)
        XCTAssertEqual(result.date.description, "2020-01-27 16:02:10 +0000")
    }

    func testDateWithoutMilliseconds() {
        let input = """
        {
          "date": "2020-01-27T17:02:10Z"
        }
        """.data(using: .utf8)!

        let result = try! decoder.decode(Bazinga.self, from: input)
        XCTAssertEqual(result.date.description, "2020-01-27 17:02:10 +0000")
    }

    func testDateWithoutMillisecondsWithTimezone() {
        let input = """
        {
          "date": "2020-01-27T17:02:10+0100"
        }
        """.data(using: .utf8)!

        let result = try! decoder.decode(Bazinga.self, from: input)
        XCTAssertEqual(result.date.description, "2020-01-27 16:02:10 +0000")
    }
}
