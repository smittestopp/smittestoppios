import Foundation
import XCTest
@testable import Smittestopp

fileprivate extension Int {
    var seconds: TimeInterval { return TimeInterval(self) }
    var minutes: TimeInterval { return TimeInterval(self) * 60 }
    var hours: TimeInterval { return TimeInterval(self) * 60 * 60 }
}

class DateIso8601Tests: XCTestCase {
    /// Compares date with given date components (which are expected to be in UTC)
    private func assertDateEquals(
        _ date: Date?,
        year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int,
        file: StaticString = #file, line: UInt = #line) {
        guard let date = date else {
            XCTFail("date is nil", file: file, line: line)
            return
        }

        let components = Calendar.current.dateComponents(in: TimeZone(identifier: "GMT")!, from: date)

        XCTAssertEqual(
            components.year, year,
            "year mismatch",
            file: file, line: line)

        XCTAssertEqual(
            components.month, month,
            "month mismatch",
            file: file, line: line)

        XCTAssertEqual(
            components.day, day,
            "day mismatch",
            file: file, line: line)

        XCTAssertEqual(
            components.hour, hour,
            "hour mismatch",
            file: file, line: line)

        XCTAssertEqual(
            components.minute, minute,
            "minute mismatch",
            file: file, line: line)

        XCTAssertEqual(
            components.second, second,
            "second mismatch",
            file: file, line: line)
    }

    func testWithoutMilliseconds() {
        assertDateEquals(
            Date(iso8601String: "2020-01-27T17:02:10Z"),
            year: 2020, month: 1, day: 27, hour: 17, minute: 2, second: 10)

        assertDateEquals(
            Date(iso8601String: "2020-01-27T17:02:10+00:00"),
            year: 2020, month: 1, day: 27, hour: 17, minute: 2, second: 10)

        assertDateEquals(
            Date(iso8601String: "2020-01-27T17:02:10+01:00"),
            year: 2020, month: 1, day: 27, hour: 16, minute: 2, second: 10)
    }

    func testWithMilliseconds() {
        assertDateEquals(
            Date(iso8601String: "2020-01-27T17:02:10.123Z"),
            year: 2020, month: 1, day: 27, hour: 17, minute: 2, second: 10)

        assertDateEquals(
            Date(iso8601String: "2020-01-27T17:02:10.123+00:00"),
            year: 2020, month: 1, day: 27, hour: 17, minute: 2, second: 10)

        assertDateEquals(
            Date(iso8601String: "2020-01-27T17:02:10.123+01:00"),
            year: 2020, month: 1, day: 27, hour: 16, minute: 2, second: 10)
    }
}
