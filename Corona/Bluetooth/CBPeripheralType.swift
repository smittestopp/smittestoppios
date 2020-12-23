import CoreBluetooth
import Foundation

protocol CBPeripheralType: class {
    var identifier: UUID { get }
    var _delegate: CBPeripheralTypeDelegate? { get set }
    var services: [CBService]? { get }
    func discoverServices(_ serviceUUIDs: [CBUUID]?)
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)
    func readValue(for characteristic: CBCharacteristic)
}

extension CBPeripheral: CBPeripheralType {
    var _delegate: CBPeripheralTypeDelegate? {
        get {
            return delegate as? CBPeripheralTypeDelegate
        }
        set {
            delegate = newValue as? CBPeripheralDelegateType
        }
    }
}

protocol CBPeripheralTypeDelegate {
    func _peripheral(_ peripheral: CBPeripheralType, didDiscoverServices error: Error?)
    func _peripheral(_ peripheral: CBPeripheralType, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    func _peripheral(_ peripheral: CBPeripheralType, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
}

typealias CBPeripheralDelegateType = CBPeripheralDelegate & CBPeripheralTypeDelegate
