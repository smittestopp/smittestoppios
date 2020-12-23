import Foundation
@testable import Smittestopp

class MockDateService: DateServiceProviding {
    var now: Date = {
        .makeGMT(year: 2000, month: 11, day: 23,
                 hour: 12, minute: 34, second: 56)
    }()
}
