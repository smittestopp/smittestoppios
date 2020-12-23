import CoreLocation
import Foundation
import XCTest
@testable import Smittestopp

class LocationManagerTests: XCTestCase {
    var localStorage: MockLocalStorageService!
    var manager: LocationManager!
    var offlineStore: OfflineStore!
    var uploader: MockUploader!

    override func setUp() {
        localStorage = MockLocalStorageService()

        offlineStore = OfflineStore(dbFileName: testOfflineStoreFileName, dbKey: "123")
        offlineStore.removeAllData()

        uploader = MockUploader()
        manager = LocationManager(appConfiguration: .unitTest,
                                  localStorage: localStorage,
                                  clLocationManager: MockCLLocationManager(locationProvider: .simple),
                                  offlineStore: offlineStore,
                                  uploader: uploader,
                                  bleIdentifierService: MockBLEIdentifierService())
    }

    override func tearDown() {
        offlineStore.removeAllData()
    }

    func testLocationManagerGPSEnable() {
        XCTAssertFalse(manager.gpsState.isEnabled, "should start false")
        manager.setGPSEnabled(true)
        XCTAssertTrue(manager.gpsState.isEnabled, "should be enabled")
    }

    func testLocationUpdatesUploaded() {
        manager.setGPSEnabled(true)

        wait(timeout: 3) { expectation in

            XCTAssertEqual(self.uploader.uploadTriggerCount, 3)
            XCTAssertNil(self.manager.lastKnownLocationForRegionMonitoring)

            expectation.fulfill()
        }
    }

    func testRegionMonitoring() {
        let locationManager = MockCLLocationManager(locationProvider: .sameLocation)
        let managerWithSameLocationProvider = LocationManager(appConfiguration: .unitTest,
                                                              localStorage: localStorage,
                                                              clLocationManager: locationManager,
                                                              offlineStore: offlineStore,
                                                              uploader: uploader,
                                                              bleIdentifierService: MockBLEIdentifierService())

        managerWithSameLocationProvider.setGPSEnabled(true)

        wait(timeout: 4) { expectation in
            XCTAssertNotNil(managerWithSameLocationProvider.lastKnownLocationForRegionMonitoring)
            XCTAssertEqual(locationManager.monitoredRegions.count, 1)
            expectation.fulfill()
        }
    }
}

extension XCTestCase {
    func wait(description: String = #function,
              timeout: TimeInterval = 0.5,
              testingClosure: @escaping (_ expectation: XCTestExpectation) -> Void) {
        let expectation = self.expectation(description: description)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeout - 0.1) {
            testingClosure(expectation)
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
