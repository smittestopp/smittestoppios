import Foundation
import SnapshotTesting
import XCTest
@testable import Smittestopp

class SnapshotSettingsViewControllerTests: XCTestCase {
    struct MockDependencyContainer:
       HasLocalStorageService, HasLoginService, HasBundleService,
    HasLocationManager, HasIoTHubService, HasOfflineStore, HasApiService, HasBLEIdentifierService {
        var mockLocalStorage = MockLocalStorageService()
        var mockLoginService = MockLoginService()
        var mockBundle = MockBundleService()
        var mockLocationManager = MockLocationManager()
        var mockIoTHubService = MockIoTHubService()
        var mockApiService = MockApiService()
        var mockBleIdentifierService = MockBLEIdentifierService()

        var localStorage: LocalStorageServiceProviding { return mockLocalStorage }
        var loginService: LoginServiceProviding { return mockLoginService }
        var bundle: BundleServiceProviding { return mockBundle }
        var locationManager: LocationManagerProviding { return mockLocationManager }
        var iotHubService: IoTHubServiceProviding { return mockIoTHubService }
        var offlineStore: OfflineStore { return OfflineStore(dbKey: "123") }
        var apiService: ApiServiceProviding { return mockApiService }
        var bleIdentifierService: BLEIdentifierServiceProviding { mockBleIdentifierService }
    }

    func testSnapshotMonitoringDeactivated() {
        let deps = MockDependencyContainer()
        deps.mockLocalStorage.isTrackingEnabled = false

        let vc = SettingsViewController(dependencies: deps)
        assertSnapshotsWithTraits(matching: vc)
    }

    func testSnapshotMonitoringActivated() {
        let deps = MockDependencyContainer()
        deps.mockLocalStorage.isTrackingEnabled = true

        let vc = SettingsViewController(dependencies: deps)
        assertSnapshotsWithTraits(matching: vc)
    }

    func testVersionStringInReleaseDevBuilds() {
        let deps = MockDependencyContainer()
        deps.mockBundle.appConfigurationTarget = .releaseDev
        deps.mockBundle.buildNumber = "9999"
        deps.mockBundle.gitCommit = "abcdefghijklmnopqrstuvwxyz0123456789"

        let vc = SettingsViewController(dependencies: deps)
        assertSnapshotsWithTraits(matching: vc)
    }
}
