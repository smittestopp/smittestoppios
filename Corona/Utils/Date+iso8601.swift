import Foundation

extension Date {
    // Constructs Date from an ISO8601-formatted dates that can be with and without milliseconds.
    // E.g.
    //   2019-12-02T11:13:24Z
    //   2020-01-28T08:17:09.123+00:00
    // and
    //   2019-12-02T11:13:24.123Z
    //   2020-01-28T08:17:09+00:00
    init?(iso8601String stringValue: String) {
        let iso8601WithMilliseconds = ISO8601DateFormatter()
        iso8601WithMilliseconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601WithMilliseconds.date(from: stringValue) {
            self = date
            return
        }

        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: stringValue) {
            self = date
            return
        }

        return nil
    }
}
