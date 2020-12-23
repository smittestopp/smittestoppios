import Foundation
import XCTest
@testable import Smittestopp

class BLECentralTests: XCTestCase {
    var central: BLECentral!
    var localStorage: MockLocalStorageService!
    var centralManager: MockCBCentralManager!
    var offlineStore: OfflineStore!
    var uploader: MockUploader!

    override func setUp() {
        localStorage = MockLocalStorageService()
        centralManager = MockCBCentralManager()

        offlineStore = OfflineStore(dbFileName: testOfflineStoreFileName, dbKey: localStorage.dbKey)
        offlineStore.removeAllData()

        uploader = MockUploader()
        central = BLECentral(offlineStore: offlineStore,
                              uploader: uploader)
        central.manager = centralManager
        centralManager.delegate = central
        centralManager._delegate = central
    }

    func testStartStop() {
        central.start()
        XCTAssertFalse(centralManager.isScanning)

        central.stop()
        central.start()
        XCTAssertFalse(centralManager.isScanning)

        centralManager.powerOn()
        XCTAssertTrue(centralManager.isScanning)

        central.stop()
        XCTAssertFalse(centralManager.isScanning)
    }

    func testDiscoverPeripheral() {
        centralManager.powerOn()
        central.start()

        let date = Date.makeGMT(year: 2000, month: 11, day: 23, hour: 12, minute: 34, second: 56)

        let location = GPSData(
            from: date, to: date,
            lat: 12, lon: 34, accuracy: 45, speed: 78, altitude: 89, altitudeAccuracy: 90)
        central.lastKnownLocation = location

        let peripheral = MockCBPeripheral()
        centralManager.discoverPeripheral(peripheral)

        wait(timeout: 11.0, testingClosure: { expectation in
            XCTAssertTrue(self.offlineStore.markDataForUpload(withType: .bluetooth, limit: 100))
            let data = self.offlineStore.getDataForUpload(withType: .bluetooth)
            XCTAssertEqual(data.count, 1)

            guard case let .bluetooth(bleData) = data else {
                XCTFail()
                return
            }

            XCTAssertEqual(bleData.count, 1)
            XCTAssertEqual(bleData[0].lastKnownLocation, BLEDetectionData.Location(location))

            XCTAssertEqual(bleData[0].uuid, peripheral.bluetoothId)
            XCTAssertEqual(peripheral.discoverServicesCalls, 1)
            XCTAssertEqual(peripheral.discoverCharacteristicsCalls, 1)
            XCTAssertEqual(peripheral.readValueCalls, 1)
            XCTAssertEqual(self.uploader.uploadTriggerCount, 1)
            expectation.fulfill()
        })
    }

}
