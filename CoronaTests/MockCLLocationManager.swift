import CoreLocation
import Foundation

@testable import Smittestopp

class MockCLLocationManager: CLLocationManagerType {
    private lazy var dummyLocationManager = CLLocationManager()

    static func locationServicesEnabled() -> Bool { isLocationServicesEnabled }
    static func authorizationStatus() -> CLAuthorizationStatus { currentAuthorizationStatus }

    weak var delegate: CLLocationManagerDelegate?
    var distanceFilter: CLLocationDistance = kCLDistanceFilterNone
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    var allowsBackgroundLocationUpdates: Bool = false
    var location: CLLocation?
    var monitoredRegions = Set<CLRegion>()

    private static var isLocationServicesEnabled = false
    private static var currentAuthorizationStatus: CLAuthorizationStatus = .notDetermined

    private var locationProvider: LocationProvider {
        didSet {
            stopUpdatingLocation()
        }
    }

    private var locationUpdateTimers = [Timer]()

    init(locationProvider: LocationProvider = .simple) {
        self.locationProvider = locationProvider
    }

    func requestAlwaysAuthorization() {
        Self.currentAuthorizationStatus = .authorizedAlways
        Self.isLocationServicesEnabled = true
        delegate?.locationManager?(dummyLocationManager, didChangeAuthorization: Self.authorizationStatus())
    }

    func startUpdatingLocation() {
        for location in locationProvider.locations {
            let timer = Timer(fire: location.timestamp, interval: 0, repeats: false) { _ in
                self.location = location
                self.delegate?.locationManager?(self.dummyLocationManager, didUpdateLocations: [location])
            }
            locationUpdateTimers.append(timer)
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stopUpdatingLocation() {
        locationUpdateTimers.forEach { timer in
            timer.invalidate()
        }
        locationUpdateTimers.removeAll()
    }

    func startMonitoringSignificantLocationChanges() { }

    func stopMonitoringSignificantLocationChanges() { }

    func stopMonitoring(for region: CLRegion) {
        monitoredRegions.remove(region)
    }

    func startMonitoring(for region: CLRegion) {
        monitoredRegions.insert(region)
    }

    func startRangingBeacons(in _: CLBeaconRegion) {
    }

    func stopRangingBeacons(in _: CLBeaconRegion) {
    }
}

struct LocationProvider {
    var locations: [CLLocation]

    static var simple: LocationProvider {
        LocationProvider(locations:
            [CLLocation(coordinate: CLLocationCoordinate2D(latitude: 12, longitude: 12),
                        altitude: 12,
                        horizontalAccuracy: 0,
                        verticalAccuracy: 0,
                        timestamp: Date()),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 12 + oneHundredMetersInDegrees, longitude: 12 + oneHundredMetersInDegrees),
                        altitude: 12,
                        horizontalAccuracy: 0,
                        verticalAccuracy: 0,
                        timestamp: Date().addingTimeInterval(0.1)),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 12 + oneKilometerInDegrees, longitude: 12 + oneKilometerInDegrees),
                        altitude: 12,
                        horizontalAccuracy: 0,
                        verticalAccuracy: 0,
                        timestamp: Date().addingTimeInterval(0.2)),
            ]
        )
    }

    static var sameLocation: LocationProvider {
        LocationProvider(locations:
            [CLLocation(coordinate: CLLocationCoordinate2D(latitude: 12, longitude: 12),
                        altitude: 12,
                        horizontalAccuracy: 0,
                        verticalAccuracy: 0,
                        timestamp: Date()),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 12, longitude: 12),
                        altitude: 12,
                        horizontalAccuracy: 0,
                        verticalAccuracy: 0,
                        timestamp: Date().addingTimeInterval(2.1)), // greater than PAUSE_GPS_IDLE_PERIOD
            ]
        )
    }
}

var oneMeterInDegrees = 0.00001
var oneHundredMetersInDegrees = 100 * oneMeterInDegrees
var oneKilometerInDegrees = 1000 * oneMeterInDegrees
