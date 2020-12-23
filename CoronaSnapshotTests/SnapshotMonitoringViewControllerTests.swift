import Foundation
import SnapshotTesting
import XCTest
@testable import Smittestopp

class SnapshotMonitoringViewControllerTests: XCTestCase {
    struct MockDependencyContainer: MonitoringViewController.Dependencies {
        var mockLocalStorage = MockLocalStorageService()
        var mockLoginService = MockLoginService()
        var mockBundle = MockBundleService()
        var mockLocationManager = MockLocationManager()
        var mockIoTHubService = MockIoTHubService()
        var mockDateOfBirthUploader = MockDateOfBirthUploader()

        var localStorage: LocalStorageServiceProviding { return mockLocalStorage }
        var loginService: LoginServiceProviding { return mockLoginService }
        var bundle: BundleServiceProviding { return mockBundle }
        var locationManager: LocationManagerProviding { return mockLocationManager }
        var iotHubService: IoTHubServiceProviding { return mockIoTHubService }
        var dateOfBirthUploader: DateOfBirthUploaderProviding { return mockDateOfBirthUploader }
    }

    private func snapshot(isTrackingEnabled: Bool, gps: GPSState, bluetooth: BluetoothState, isAgeVerified: Bool = true,
                  file: StaticString = #file, testName: String = #function, line: UInt = #line) {
        let deps = MockDependencyContainer()

        deps.mockLocalStorage.isTrackingEnabled = isTrackingEnabled
        deps.mockLocationManager.gpsState = gps
        deps.mockLocationManager.bluetoothState = bluetooth
        deps.mockLocalStorage.dateOfBirth = isAgeVerified ? deps.mockLocalStorage.dateOfBirth : nil

        let vc = MonitoringViewController(dependencies: deps)
        assertSnapshotsWithTraits(matching: vc, file: file, testName: testName, line: line)
    }

    func testAllEnabled() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .enabledAlways, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .allowedAlways, power: .on))
    }

    func testAllEnabledAndAgeNotVerified() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .enabledAlways, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .allowedAlways, power: .on),
                 isAgeVerified: false)
    }

    func testMonitoringDisabledByUser() {
        snapshot(isTrackingEnabled: false,
                 gps: .init(authorizationStatus: .denied, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .allowedAlways, power: .on))
    }

    func testMonitoringDisabledByUserAndAgeNotVerified() {
        snapshot(isTrackingEnabled: false,
                 gps: .init(authorizationStatus: .denied, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .allowedAlways, power: .on),
                 isAgeVerified: false)
    }

    func testLocationServicesGloballyOff() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .enabledAlways, isLocationServiceEnabled: false),
                 bluetooth: .init(authorization: .allowedAlways, power: .on))
    }

    func testLocationServicesGloballyOffAndAgeNotVerified() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .enabledAlways, isLocationServiceEnabled: false),
                 bluetooth: .init(authorization: .allowedAlways, power: .on),
                 isAgeVerified: false)
    }

    func testLocationWhenInUse() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .enabledWhenInUse, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .allowedAlways, power: .on))
    }

    func testLocationWhenInUseAndAgeNotVerified() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .enabledWhenInUse, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .allowedAlways, power: .on),
                 isAgeVerified: false)
    }

    func testLocationDenied() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .denied, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .allowedAlways, power: .on))
    }

    func testLocationDeniedAndAgeNotVerified() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .denied, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .allowedAlways, power: .on),
                 isAgeVerified: false)
    }

    func testLocationNotDetermined() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .notDetermined, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .allowedAlways, power: .on))
    }

    func testLocationNotDeterminedAndAgeNotVerified() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .notDetermined, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .allowedAlways, power: .on),
                 isAgeVerified: false)
    }

    func testBluetoothNotDetermined() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .enabledAlways, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .notDetermined, power: .on))
    }

    func testBluetoothNotDeterminedAndAgeNotVerified() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .enabledAlways, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .notDetermined, power: .on),
                 isAgeVerified: false)
    }

    func testBluetoothDenied() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .enabledAlways, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .denied, power: .on))
    }

    func testBluetoothDeniedAndAgeNotVerified() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .enabledAlways, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .denied, power: .on),
                 isAgeVerified: false)
    }

    func testLocationServicesGloballyOffAndBluetoothDenied() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .enabledAlways, isLocationServiceEnabled: false),
                 bluetooth: .init(authorization: .denied, power: .on))
    }

    func testLocationServicesGloballyOffAndBluetoothDeniedAndAgeNotVerified() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .enabledAlways, isLocationServiceEnabled: false),
                 bluetooth: .init(authorization: .denied, power: .on),
                 isAgeVerified: false)
    }

    func testLocationDeniedAndBluetoothDenied() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .denied, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .denied, power: .on))
    }

    func testLocationDeniedAndBluetoothDeniedAndAgeNotVerified() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .denied, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .denied, power: .on),
                 isAgeVerified: false)
    }

    func testLocationNotDeterminedAndBluetoothDenied() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .notDetermined, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .denied, power: .on))
    }

    func testLocationNotDeterminedAndBluetoothDeniedAndAgeNotVerified() {
        snapshot(isTrackingEnabled: true,
                 gps: .init(authorizationStatus: .notDetermined, isLocationServiceEnabled: true),
                 bluetooth: .init(authorization: .denied, power: .on),
                 isAgeVerified: false)
    }
}
