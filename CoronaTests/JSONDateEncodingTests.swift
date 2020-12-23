import XCTest
@testable import Smittestopp

class JSONDateEncodingTests: XCTestCase {
    struct Bazinga: Codable {
        let date: Date
    }

    let encoder = JSONEncoder.standard

    func testDateEncoding() {
        let object = Bazinga(date: Date(timeIntervalSince1970: 0613162785))

        let data = try! encoder.encode(object)
        let string = String(data: data, encoding: .utf8)!
        XCTAssertEqual(string, "{\"date\":\"1989-06-06T18:59:45Z\"}")
    }
}
