import Foundation

enum StorableGPSEvent {
    /// Location insert
    case insert(GPSData)

    /// Location update
    case update(GPSData)

    /// User was stationary for a period of time
    case stationary(GPSStationaryData)
}
