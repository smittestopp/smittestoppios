import Foundation

extension Date {
    func years(sinceDate: Date) -> Int? {
        Calendar.current.dateComponents([.year], from: sinceDate, to: self).year
    }
}
