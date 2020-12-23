import Foundation

struct BLEDetectionData: Equatable {
    struct Location: Equatable {
        let latitude: Double
        let longitude: Double
        let accuracy: Double
        let timestamp: Date

        init(latitude: Double, longitude: Double, accuracy: Double, timestamp: Date) {
            self.latitude = latitude
            self.longitude = longitude
            self.accuracy = accuracy
            self.timestamp = timestamp
        }

        init?(_ value: GPSData?) {
            guard let value = value else {
                return nil
            }
            latitude = value.lat
            longitude = value.lon
            accuracy = value.accuracy
            timestamp = value.to
        }
    }

    let uuid: String
    let rssiReading: BLERSSIReading
    let txPower: Int?
    let lastKnownLocation: Location?
}
