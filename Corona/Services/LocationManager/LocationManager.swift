import CoreBluetooth
import CoreLocation
import Foundation
import NotificationCenter

fileprivate extension String {
    static let locationManager = "LocationManager"
}

protocol LocationManagerProviding {
    var gpsState: GPSState { get }

    var bluetoothState: BluetoothState { get }

    func setGPSEnabled(_ enabled: Bool)

    func setBluetoothEnabled(_ enabled: Bool)
}

protocol HasLocationManager {
    var locationManager: LocationManagerProviding { get }
}

class LocationManager: NSObject, LocationManagerProviding {
    private(set) var gpsState: GPSState {
        didSet {
            let name = NotificationType.GPSStateUpdated
            NotificationCenter.default.post(name: name, object: self, userInfo: [
                "old": oldValue,
            ])
        }
    }

    private(set) var bluetoothState: BluetoothState {
        didSet {
            let name = NotificationType.BluetoothStateUpdated
            NotificationCenter.default.post(name: name, object: self, userInfo: [
                "old": oldValue,
            ])
        }
    }

    private var manager: CLLocationManagerType
    private var offlineStore: OfflineStore
    private var uploader: UploaderType
    private var appConfiguration: AppConfiguration
    private let localStorage: LocalStorageServiceProviding

    private var beaconRegion: CLBeaconRegion = {
        return CLBeaconRegion(proximityUUID: BLEPeripheral.beaconUUID,
                              major: BLEPeripheral.beaconMajor,
                              minor: BLEPeripheral.beaconMinor,
                              identifier: "identifier.beacon")
    }()

    private let bleCentral: BLECentral
    private let blePeripheral: BLEPeripheral
    private var bleBackgroundScanTimer: Timer?

    /// The last known location for the device.
    var lastKnownLocation: CLLocation?
    var lastKnownLocationForRegionMonitoring: GPSData?
    var pausedGPSTimer: Timer?

    // Consider points 10 meters apart (excluding accuracy) to be the same point
    // The larger this number the fewer GPS points will get send to the server
    let EXTRA_DISTANCE_ALLOWANCE: Double = 10
    lazy var PAUSE_GPS_IDLE_PERIOD: Double = appConfiguration.locationManager.PAUSE_GPS_IDLE_PERIOD
    lazy var PAUSE_GPS_REGION_RADIUS: Double = appConfiguration.locationManager.PAUSE_GPS_REGION_RADIUS
    let PAUSE_GPS_REGION_IDENTIFIER = "PAUSE_GPS_REGION_IDENTIFIER"
    /// Desired accuracy when tracking location
    let desiredAccuracyNormal: CLLocationAccuracy = kCLLocationAccuracyNearestTenMeters
    /// Desired accuracy when live tracking is paused and we set up a geofence.
    let desiredAccuracyPaused: CLLocationAccuracy = kCLLocationAccuracyThreeKilometers

    init(appConfiguration: AppConfiguration = AppConfiguration.shared,
         localStorage: LocalStorageServiceProviding,
         clLocationManager: CLLocationManagerType = CLLocationManager(),
         offlineStore: OfflineStore,
         uploader: UploaderType,
         bleIdentifierService: BLEIdentifierServiceProviding) {

        self.appConfiguration = appConfiguration
        self.localStorage = localStorage
        manager = clLocationManager
        self.offlineStore = offlineStore
        self.uploader = uploader

        let bleCentral = BLECentral(offlineStore: offlineStore, uploader: uploader)
        let blePeripheral = BLEPeripheral(localStorage: localStorage, bleIdentifierService: bleIdentifierService)

        let bluetoothAuthorization: BluetoothAuthorizationStatus
        if #available(iOS 13.1, *) {
            bluetoothAuthorization = CBPeripheralManager.authorization.bluetoothAuthorization
        } else if #available(iOS 13.0, *) {
            let authorization = blePeripheral.manager.authorization
            bluetoothAuthorization = authorization.bluetoothAuthorization
        } else {
            bluetoothAuthorization = CBPeripheralManager.authorizationStatus().bluetoothAuthorization
        }
        bluetoothState = BluetoothState(authorization: bluetoothAuthorization, power: .notDetermined)

        self.blePeripheral = blePeripheral
        self.bleCentral = bleCentral

        gpsState = GPSState(authorizationStatus: .init(type(of: manager).authorizationStatus()),
                            isLocationServiceEnabled: type(of: manager).locationServicesEnabled())

        super.init()

        blePeripheral.delegate = self
        bleCentral.delegate = self
        manager.delegate = self
    }

    func setGPSEnabled(_ enabled: Bool) {
        if enabled {
            Logger.debug("Enabling GPS monitoring", tag: .locationManager)
            // Stop possible region monitoring
            stopRegionMonitoring()

            manager.requestAlwaysAuthorization()

            manager.desiredAccuracy = desiredAccuracyNormal
            manager.allowsBackgroundLocationUpdates = true
            manager.startMonitoringSignificantLocationChanges()
            manager.startUpdatingLocation()
        } else {
            Logger.debug("Disabling GPS monitoring", tag: .locationManager)
            // Stop possible region monitoring
            stopRegionMonitoring()
            stopAllRegionMonitoring()
            manager.stopMonitoringSignificantLocationChanges()
            manager.stopUpdatingLocation()
        }
    }

    func setBluetoothEnabled(_ enabled: Bool) {
        if enabled {
            blePeripheral.start()
            bleCentral.start()
            if bleBackgroundScanTimer == nil {
                bleBackgroundScanTimer = Timer.scheduledTimer(timeInterval: 300.0,
                                                               target: self,
                                                               selector: #selector(bleBackgroundScan),
                                                               userInfo: nil,
                                                               repeats: true)
            }
        } else {
            blePeripheral.stop()
            bleCentral.stop()
            bleBackgroundScanTimer?.invalidate()
            bleBackgroundScanTimer = nil
        }
    }

    private func updateGPSState(_ authorizationStatus: GPSAuthorizationStatus? = nil, isLocationServiceEnabled: Bool? = nil) {
        gpsState = GPSState(
            authorizationStatus: authorizationStatus ?? gpsState.authorizationStatus,
            isLocationServiceEnabled: isLocationServiceEnabled ?? gpsState.isLocationServiceEnabled)
    }

    private func updateBluetoothState(_ authorization: BluetoothAuthorizationStatus? = nil, power: BluetoothPowerState? = nil) {
        bluetoothState = BluetoothState(
            authorization: authorization ?? bluetoothState.authorization,
            power: power ?? bluetoothState.power)
    }

    func startBeaconMonitoring() {
        manager.startRangingBeacons(in: beaconRegion)
    }

    func stopBeaconMonitoring() {
        manager.stopRangingBeacons(in: beaconRegion)
    }

    @objc func bleBackgroundScan() {
        guard UIApplication.shared.applicationState == .background else {
            Logger.debug("bleBackgroundScan skipped: app is not backgrounded.", tag: .locationManager)
            return
        }

        guard gpsState.isEnabled else {
            Logger.debug("bleBackgroundScan skipped: gps is not enabled.", tag: .locationManager)
            return
        }

        guard UIApplication.shared.backgroundTimeRemaining > 20.0 else {
            Logger.debug("bleBackgroundScan skipped: not enough background time remaining.", tag: .locationManager)
            return
        }

        // Central scanning is restarted to clear duplicate filter.
        bleCentral.stopScanning()
        startBeaconMonitoring()
        // Note that the duplicate filter can be disabled even in the background here.
        // However, this dramatically reduces battery life, and should be avoided.
        bleCentral.startScanning()

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10.0) { [weak self] in
            self?.stopBeaconMonitoring()
        }
    }
}

// MARK: - CLLocationManagerDelegate

let dbGPSSemaphore = DispatchSemaphore(value: 1)

extension LocationManager: CLLocationManagerDelegate {
    func isSameLocation(lastLoc: GPSData, newLoc: CLLocation) -> Bool {
        let distM = CLLocation(latitude: lastLoc.lat, longitude: lastLoc.lon).distance(from: newLoc)
        if distM > lastLoc.accuracy + newLoc.horizontalAccuracy + EXTRA_DISTANCE_ALLOWANCE ||
            lastLoc.to.timeIntervalSince(newLoc.timestamp) > PAUSE_GPS_IDLE_PERIOD + 20 {
            return false
        }
        return true
    }

    func registerNewLocation(newLoc: CLLocation) -> GPSData {
        if CSVFileApi.shared.enabled {
            // This API is never enabled in production
            CSVFileApi.shared.write(
                lat: newLoc.coordinate.latitude,
                lon: newLoc.coordinate.longitude,
                accuracy: newLoc.horizontalAccuracy,
                timestamp: newLoc.timestamp)
        }

        // Ensure only one thread is active here at a time
        dbGPSSemaphore.wait()

        // Get last location
        var lastLoc = offlineStore.getLatestGPSDataNotUploading()

        if lastLoc == nil || !isSameLocation(lastLoc: lastLoc!, newLoc: newLoc) {
            Logger.debug("Considered to be at a NEW location", tag: .locationManager)
            // Create a new location
            lastLoc = GPSData(newLoc)

            offlineStore.insert(.gps(.insert(lastLoc!)))

            dbGPSSemaphore.signal()

            return lastLoc!
        }

        Logger.debug("Considered to be at a SAME location", tag: .locationManager)

        // Update the last location
        // Note: if you extend something here do not forget to also extend update() in OfflineStore impl
        lastLoc!.to = newLoc.timestamp
        lastLoc!.accuracy = min(lastLoc!.accuracy, newLoc.horizontalAccuracy)
        lastLoc!.altitudeAccuracy = min(lastLoc!.altitudeAccuracy, newLoc.verticalAccuracy)

        offlineStore.insert(.gps(.update(lastLoc!)))

        dbGPSSemaphore.signal()

        return lastLoc!
    }

    // MARK: Authorization

    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        updateGPSState(.init(status), isLocationServiceEnabled: type(of: manager).locationServicesEnabled())
    }

    // MARK: Standard/significant location services

    func locationManager(_: CLLocationManager, didUpdateLocations _: [CLLocation]) {
        // a hack, we need to restructure our services/managers to avoid dependency cycles.
        (UIApplication.shared.delegate as? AppDelegate)?.heartbeatManager.sendIfNeeded()

        guard let locValue: CLLocation = manager.location else { return }

        guard locValue.horizontalAccuracy >= 0 else {
            Logger.debug("Location accuracy below 0. Ignoring GPS point", tag: .locationManager)
            return
        }

        let currentLocation = registerNewLocation(newLoc: locValue)

        if currentLocation.to.timeIntervalSince(currentLocation.from) > PAUSE_GPS_IDLE_PERIOD {
            // Longer than PAUSE_GPS_IDLE_PERIOD at the same location, switching over to region monitoring and coarse-grain GPS monitoring
            Logger.debug("At the same location from \(currentLocation.from): Switching to region monitoring", tag: .locationManager)

            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: currentLocation.lat, longitude: currentLocation.lon),
                                          radius: PAUSE_GPS_REGION_RADIUS,
                                          identifier: PAUSE_GPS_REGION_IDENTIFIER)
            lastKnownLocationForRegionMonitoring = currentLocation
            manager.startMonitoring(for: region)
        }

        // inject last known location into bluetooth events
        bleCentral.lastKnownLocation = GPSData(locValue)

        // Trigger upload listener
        uploader.uploadTrigger()
    }

    func pauseGPSUpdates() {
        manager.desiredAccuracy = desiredAccuracyPaused
        manager.distanceFilter = 3000

        pausedGPSTimer?.invalidate()
        pausedGPSTimer = Timer.scheduledTimer(timeInterval: PAUSE_GPS_IDLE_PERIOD,
                                              target: self, selector: #selector(pausedGPSStatusCheck),
                                              userInfo: nil, repeats: true)
    }

    func resumeGPSUpdates() {
        manager.desiredAccuracy = desiredAccuracyNormal
        stopRegionMonitoring()
    }

    func stopRegionMonitoring() {
        manager.distanceFilter = kCLDistanceFilterNone
        pausedGPSTimer?.invalidate()
        lastKnownLocationForRegionMonitoring = nil
    }

    func stopAllRegionMonitoring() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
    }

    @objc func pausedGPSStatusCheck() {
        if lastKnownLocationForRegionMonitoring == nil {
            Logger.error("GPS paused, but last location is not known?!?", tag: .locationManager)
            resumeGPSUpdates()
            return
        }

        if !CLLocationManager.locationServicesEnabled()
            || !gpsState.isEnabled
            || !localStorage.isTrackingEnabled {

            // Location services are no longer available, hence we can't say we are still
            // at the last known location.
            Logger.warning("Location services were disabled while paused", tag: .locationManager)

            // Resume GPS updates
            resumeGPSUpdates()
            return
        }

        // We consider ourselves to be at the same location as before. Otherwise, with
        // location services on we would get notified that we left the current region, right?
        let updatedLoc = registerNewLocation(
            newLoc: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: lastKnownLocationForRegionMonitoring!.lat, longitude: lastKnownLocationForRegionMonitoring!.lon),
                altitude: lastKnownLocationForRegionMonitoring!.altitude,
                horizontalAccuracy: lastKnownLocationForRegionMonitoring!.accuracy,
                verticalAccuracy: lastKnownLocationForRegionMonitoring!.altitudeAccuracy,
                timestamp: Date()
        ))

        Logger.debug("Inserted paused GPS event extending known location from \(updatedLoc.from) to \(updatedLoc.to)", tag: .locationManager)

        // Trigger upload listener
        uploader.uploadTrigger()
    }

    // MARK: Visit location service

    func locationManager(_: CLLocationManager, didVisit _: CLVisit) {
        // TODO
    }

    // MARK: Region monitoring / geofencing

    func locationManager(_: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == PAUSE_GPS_REGION_IDENTIFIER {
            manager.stopMonitoring(for: region)
            resumeGPSUpdates()
        }
    }

    func locationManager(_: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == PAUSE_GPS_REGION_IDENTIFIER {
            // This should hopefully never be called?
        }
    }

    func locationManager(_: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if region.identifier == PAUSE_GPS_REGION_IDENTIFIER {
            pauseGPSUpdates()
        }
    }

    func locationManager(_: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if region.identifier == PAUSE_GPS_REGION_IDENTIFIER,
            state != .inside {
            // Could not determine the device inside the region. Activating precision GPS again.
            resumeGPSUpdates()
        }
    }

    func locationManager(_: CLLocationManager, monitoringDidFailFor _: CLRegion?, withError error: Error) {
        Logger.error("Region monitoring failed \(error.localizedDescription)", tag: .locationManager)
        resumeGPSUpdates()
    }

    func locationManager(_: CLLocationManager, didRangeBeacons _: [CLBeacon], in _: CLBeaconRegion) {
        Logger.debug("Did range for beacons", tag: .locationManager)
    }

    func locationManager(_: CLLocationManager, rangingBeaconsDidFailFor _: CLBeaconRegion, withError _: Error) {
        Logger.debug("Did fail to range for beacons", tag: .locationManager)
    }

    // MARK: Heading monitoring

    func locationManager(_: CLLocationManager, didUpdateHeading _: CLHeading) {
        // TODO
    }

    // MARK: Life-cycle handling

    func locationManagerDidPauseLocationUpdates(_: CLLocationManager) {
        // TODO
    }

    func locationManagerDidResumeLocationUpdates(_: CLLocationManager) {
        // TODO
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        // TODO
        Logger.error("Failed: \(error)", tag: .locationManager)
    }

    func locationManager(_: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        // TODO
        Logger.error("Finished deferred updates with error: \(String(describing: error))", tag: .locationManager)
    }
}

extension LocationManager: BLECentralDelegate {
    func centralDidUpdateState(_ central: BLECentral) {
        let manager = central.manager
        switch manager.state {
        case .poweredOn:
            updateBluetoothState(power: .on)
        case .poweredOff:
            updateBluetoothState(power: .off)
        case .unknown, .resetting, .unsupported, .unauthorized:
            break
        @unknown default:
            break
        }
    }
}

extension LocationManager: BLEPeripheralDelegate {
    func peripheralDidUpdateState(_ peripheral: BLEPeripheral) {
        if #available(iOS 13.0, *) {
            let authorization = peripheral.manager.authorization.bluetoothAuthorization
            updateBluetoothState(authorization)
        } else {
            updateBluetoothState(CBPeripheralManager.authorizationStatus().bluetoothAuthorization)
        }
    }
}
