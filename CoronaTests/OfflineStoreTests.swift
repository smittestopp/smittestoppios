import CoreLocation
import Foundation
import XCTest
@testable import Smittestopp

var testOfflineStoreFileName = "offline_store_tests.sqlite"

class OfflineStoreTests: XCTestCase {

    var offlineStore: OfflineStore!

    override func setUp() {
        offlineStore = OfflineStore(dbFileName: testOfflineStoreFileName, dbKey: "123")
        offlineStore.removeAllData()
    }

    func testCreateOfflineStore() {
        XCTAssertEqual(offlineStore.getBLEDataForUpload().count, 0)
        XCTAssertEqual(offlineStore.getGPSDataForUpload().count, 0)
        XCTAssertEqual(offlineStore.getLatestGPSDataNotUploading(), nil)
    }

    func testSaveBluetoothData() {
        let date = Utils.shared.dateFromString(str: "2020-01-01T00:00:00Z")!
        let rssi = -10

        let reading = BLEDetectionData(uuid: "asdf",
                                      rssiReading: .init(timestamp: date, RSSI: rssi),
                                      txPower: nil,
                                      lastKnownLocation: .init(latitude: 12, longitude: 34, accuracy: 56, timestamp: date))
        let event = StorableEvent.bluetooth(StorableBLEEvent.rssiReading(reading))
        offlineStore.insert(event)

        XCTAssertTrue(offlineStore.markDataForUpload(withType: .bluetooth, limit: 1), "should save data")
        XCTAssertEqual(offlineStore.getBLEDataForUpload().count, 1, "should have a count of data for upload")

        guard let bleData = offlineStore.getBLEDataForUpload().first else {
            XCTFail("should have a datum")
            return
        }

        XCTAssertEqual(bleData, reading)
    }

    func testSaveGPSData() {
        let fromDate = Utils.shared.dateFromString(str: "2020-01-01T00:00:00Z")!
        let toDate = Utils.shared.dateFromString(str: "2020-01-01T00:01:00Z")!

        let gpsData = GPSData(from: fromDate,
                              to: toDate,
                              lat: 12,
                              lon: -20,
                              accuracy: 0,
                              speed: 0,
                              altitude: 0,
                              altitudeAccuracy: 0)
        let event = StorableEvent.gps(StorableGPSEvent.insert(gpsData))

        offlineStore.insert(event)

        XCTAssertTrue(offlineStore.markDataForUpload(withType: .gps, limit: 1), "should save data")
        XCTAssertEqual(offlineStore.getGPSDataForUpload().count, 1, "should have a count of data for upload")

        guard let storeData = offlineStore.getGPSDataForUpload().first else {
            XCTFail("should have a datum")
            return
        }

        XCTAssertEqual(gpsData, storeData)

        var updatedGpsData = gpsData
        updatedGpsData.lat = 13

        let updateEvent = StorableGPSEvent.update(updatedGpsData)
        offlineStore.insert(StorableEvent.gps(updateEvent))
        XCTAssertTrue(offlineStore.markDataForUpload(withType: .gps, limit: 1), "should save data")
        XCTAssertEqual(offlineStore.getGPSDataForUpload().count, 1, "should have a count of data for upload")

        guard let updatedStoreData = offlineStore.getGPSDataForUpload().first else {
            XCTFail("should have a datum")
            return
        }

        XCTAssertNotEqual(updatedGpsData, updatedStoreData)
        XCTAssertEqual(gpsData.lat, updatedStoreData.lat)
        XCTAssertEqual(gpsData.lon, updatedStoreData.lon)
    }
}
