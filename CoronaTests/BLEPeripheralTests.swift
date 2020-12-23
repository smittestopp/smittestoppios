import Foundation
import XCTest
@testable import Smittestopp

class BLEPeripheralTests: XCTestCase {
    var peripheral: BLEPeripheral!
    var localStorage: MockLocalStorageService!
    var peripheralManager: MockCBPeripheralManager!

    override func setUp() {
        localStorage = MockLocalStorageService()
        peripheralManager = MockCBPeripheralManager()
        peripheral = BLEPeripheral(localStorage: localStorage,
                                   bleIdentifierService: MockBLEIdentifierService())
        peripheral.manager = peripheralManager
        peripheralManager.delegate = peripheral
    }

    func testStartStopAdvertising() {
        peripheral.start()
        // Advertising should not start before peripheral manager is powered on.
        XCTAssertFalse(peripheralManager.isAdvertising)
        peripheralManager.powerOn()
        XCTAssertTrue(peripheralManager.isAdvertising)
        peripheral.stop()
        XCTAssertFalse(peripheralManager.isAdvertising)
    }

}
