import Foundation
import XCTest
@testable import Smittestopp

class YearMonthDayTests: XCTestCase {
    func testInitYMD() {
        let ymd = YearMonthDay(year: 2002, month: 9, day: 20)
        XCTAssertEqual(ymd.year, 2002)
        XCTAssertEqual(ymd.month, 9)
        XCTAssertEqual(ymd.day, 20)
    }

    func testInitFromStringFailsWhenNotEnoughComponents() {
        let ymd = YearMonthDay("2002")
        XCTAssertNil(ymd)
    }

    func testInitFromString() {
        let ymd = YearMonthDay("20.09.2002")
        XCTAssertNotNil(ymd)
        XCTAssertEqual(ymd!.year, 2002)
        XCTAssertEqual(ymd!.month, 9)
        XCTAssertEqual(ymd!.day, 20)
    }

    func testInitFromDate() {
        let date = Date.makeGMT(year: 2002, month: 9, day: 20, hour: 16, minute: 42, second: 59)
        let ymd = YearMonthDay(date)
        XCTAssertEqual(ymd.year, 2002)
        XCTAssertEqual(ymd.month, 9)
        XCTAssertEqual(ymd.day, 20)
    }
}
