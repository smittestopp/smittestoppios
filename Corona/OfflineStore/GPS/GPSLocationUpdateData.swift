import CoreLocation
import Foundation

struct GPSData: Codable, Equatable {
    let from: Date
    var to: Date
    var lat: Double
    var lon: Double
    var accuracy: Double
    var speed: Double
    var altitude: Double
    var altitudeAccuracy: Double

    var location: CLLocation {
        CLLocation(latitude: lat, longitude: lon)
    }
}

extension GPSData {
    init(_ location: CLLocation) {
        from = location.timestamp
        to = location.timestamp
        lat = location.coordinate.latitude
        lon = location.coordinate.longitude
        accuracy = location.horizontalAccuracy
        speed = location.speed
        altitude = location.altitude
        altitudeAccuracy = location.verticalAccuracy
    }
}
