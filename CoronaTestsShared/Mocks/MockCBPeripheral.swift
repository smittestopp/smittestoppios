
import CoreBluetooth
import Foundation
@testable import Smittestopp

class MockCBPeripheral: CBPeripheralType {
    var identifier: UUID = UUID()
    var _delegate: CBPeripheralTypeDelegate?
    lazy var services: [CBService]? = {
        let service = CBMutableService(type: BLEPeripheral.serviceUUID, primary: true)
        let characteristic = CBMutableCharacteristic(type: BLEPeripheral.deviceIdCharacteristicUUID,
                                                     properties: .read,
                                                     value: self.bluetoothId.data(using: .utf8),
                                                     permissions: .readable)
        service.characteristics = [characteristic as CBCharacteristic]
        return [service as CBService]
    }()

    func discoverServices(_: [CBUUID]?) {
        discoverServicesCalls += 1
        _delegate?._peripheral(self, didDiscoverServices: nil)
    }

    func discoverCharacteristics(_: [CBUUID]?, for service: CBService) {
        discoverCharacteristicsCalls += 1
        guard services != nil,
            services!.contains(where: { $0.uuid == service.uuid }) else {
                _delegate?._peripheral(self, didDiscoverCharacteristicsFor: service, error: CBError.invalidParameters as? Error)
                return
        }
        _delegate?._peripheral(self, didDiscoverCharacteristicsFor: service, error: nil)
    }

    func readValue(for characteristic: CBCharacteristic) {
        readValueCalls += 1
        _delegate?._peripheral(self, didUpdateValueFor: characteristic, error: nil)
    }

    var discoverServicesCalls = 0
    var discoverCharacteristicsCalls = 0
    var readValueCalls = 0

    var bluetoothId = "123456"
}
