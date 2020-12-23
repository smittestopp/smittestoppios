import Foundation

extension Date {
    static func makeGMT(year: Int, month: Int, day: Int,
                        hour: Int, minute: Int, second: Int) -> Date {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year, month: month, day: day,
            hour: hour, minute: minute, second: second).date!
    }
}
