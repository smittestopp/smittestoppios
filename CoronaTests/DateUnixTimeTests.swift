import Foundation
import XCTest
@testable import Smittestopp

class DateUnixTimeTests: XCTestCase {
    func testUnixTime() {
        let date = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2020, month: 6, day: 4,
            hour: 10, minute: 3, second: 43, nanosecond: 0).date!
        XCTAssertEqual(date.unixTime, 1591265023) // sample value from https://www.unixtimestamp.com
    }
}
