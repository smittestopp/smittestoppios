import Foundation

extension Date {
    /// Returns a number of seconds from epoch without milliseconds.
    var unixTime: Int {
        return Int(timeIntervalSince1970)
    }
}
