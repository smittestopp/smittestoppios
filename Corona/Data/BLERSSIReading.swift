import Foundation

struct BLERSSIReading: Codable, Equatable {
    let timestamp: Date
    let RSSI: Int

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.timestamp.timeIntervalSinceReferenceDate == rhs.timestamp.timeIntervalSinceReferenceDate && lhs.RSSI == rhs.RSSI
    }
}
