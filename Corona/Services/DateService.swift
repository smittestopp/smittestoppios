import Foundation

protocol DateServiceProviding: class {
    var now: Date { get }
}

protocol HasDateService {
    var dateService: DateServiceProviding { get }
}

class DateService: DateServiceProviding {
    var now: Date {
        return Date()
    }
}
