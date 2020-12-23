import Foundation

struct YearMonthDay: Equatable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// Initializes from string formatted as `dd.MM.YYYY` e.g. `31.12.2020`
    init?(_ string: String) {
        let values = string.split(separator: ".")
        guard values.count == 3 else { return nil }

        guard
            let day = Int(values[0]),
            let month = Int(values[1]),
            let year = Int(values[2])
        else {
            return nil
        }

        self.year = year
        self.month = month
        self.day = day
    }

    init(_ date: Date) {
        year = Calendar.current.component(.year, from: date)
        month = Calendar.current.component(.month, from: date)
        day = Calendar.current.component(.day, from: date)
    }

    var stringValue: String {
        return String(format: "%02d.%02d.%d", day, month, year)
    }
}
