import CoreBluetooth
import Foundation
@testable import Smittestopp

class MockCBCentralManager: CBCentralManagerType {
    var state: CBManagerState = .unknown
    var _delegate: CBCentralManagerTypeDelegate?

    func cancelPeripheralConnection(_ peripheral: CBPeripheralType) {
        connectingPeripherals = connectingPeripherals.filter { $0.identifier == peripheral.identifier }
    }

    func connect(_ peripheral: CBPeripheralType, options _: [String : Any]?) {
        connectingPeripherals.append(peripheral)
        _delegate?._centralManager(dummyCentralManager, didConnect: peripheral)
    }

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options _: [String : Any]?) {
        scanningForServiceUUIDs = serviceUUIDs
        isScanning = true
    }

    func stopScan() {
        isScanning = false
    }

    var isScanning = false
    var scanningForServiceUUIDs: [CBUUID]?
    var connectingPeripherals: [CBPeripheralType] = []
    var dummyCentralManager: CBCentralManager = CBCentralManager()
    var delegate: CBCentralManagerDelegate?

    func powerOn() {
        state = .poweredOn
        delegate?.centralManagerDidUpdateState(dummyCentralManager)
    }

    func discoverPeripheral(_ peripheral: CBPeripheralType) {
        _delegate?._centralManager(dummyCentralManager, didDiscover: peripheral, advertisementData: [:], rssi: -60)
    }
}
