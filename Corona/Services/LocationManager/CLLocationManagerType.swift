import CoreLocation
import Foundation

protocol CLLocationManagerType {
    static func locationServicesEnabled() -> Bool
    static func authorizationStatus() -> CLAuthorizationStatus

    var delegate: CLLocationManagerDelegate? { get set }
    var distanceFilter: CLLocationDistance { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var allowsBackgroundLocationUpdates: Bool { get set }
    var location: CLLocation? { get }
    var monitoredRegions: Set<CLRegion> { get }

    func requestAlwaysAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()
    func stopMonitoring(for region: CLRegion)
    func startMonitoring(for region: CLRegion)
    func startRangingBeacons(in region: CLBeaconRegion)
    func stopRangingBeacons(in region: CLBeaconRegion)
}

extension CLLocationManager: CLLocationManagerType { }
