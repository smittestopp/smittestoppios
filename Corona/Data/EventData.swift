import CoreLocation
import Foundation

enum EventData: Encodable {
    case gps([GPSEventData])
    case bluetooth([BLEEventData])
    case sync(SyncEventData)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .gps(events):
            try container.encode(events)
        case let .bluetooth(events):
            try container.encode(events)
        case let .sync(event):
            try container.encode([event])
        }
    }

    var isEmpty: Bool {
        switch self {
        case let .gps(events):
            return events.isEmpty
        case let .bluetooth(events):
            return events.isEmpty
        case .sync:
            return false
        }
    }
}

struct GPSEventData: Codable {
    let timeFrom: Date
    var timeTo: Date
    var latitude: Double
    var longitude: Double
    var accuracy: Double
    var speed: Double
    var altitude: Double
    var altitudeAccuracy: Double

    var location: CLLocation {
        CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                   altitude: altitude,
                   horizontalAccuracy: 0,
                   verticalAccuracy: altitudeAccuracy,
                   timestamp: timeFrom)
    }
}

struct BLEEventData: Codable {
    struct Location: Codable {
        let latitude: Double
        let longitude: Double
        let accuracy: Double
        let timestamp: Date
    }

    let time: Date
    let deviceId: String
    var rssi: Int
    let txPower: Int?
    let location: Location?
}

struct SyncEventData: Encodable {
    enum Status: Int, Encodable {
        case hasBluetoothAndLocation = 0
        case hasLocationOnly = 1
        case hasBluetoothOnly = 2
        case allDisabled = 3
    }

    let timestamp: Date
    let status: Status
}
