import CoreBluetooth
import Foundation

protocol CBCentralManagerType {
    var state: CBManagerState { get }
    var _delegate: CBCentralManagerTypeDelegate? { get set }

    func cancelPeripheralConnection(_ peripheral: CBPeripheralType)
    func connect(_ peripheral: CBPeripheralType, options: [String : Any]?)
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)
    func stopScan()
}

extension CBCentralManager: CBCentralManagerType {
    var _delegate: CBCentralManagerTypeDelegate? {
        get {
            return delegate as? CBCentralManagerTypeDelegate
        }
        set {
            delegate = newValue as? CBCentralManagerDelegateType
        }
    }

    convenience init(delegate: CBCentralManagerDelegateType,
                     queue: DispatchQueue?,
                     options: [String: Any]? = nil) {
        self.init(delegate: delegate as CBCentralManagerDelegate,
                  queue: queue,
                  options: options)
        _delegate = delegate
    }

    func cancelPeripheralConnection(_ peripheral: CBPeripheralType) {
        if let peripheral = peripheral as? CBPeripheral {
            cancelPeripheralConnection(peripheral)
        }
    }

    func connect(_ peripheral: CBPeripheralType, options: [String : Any]?) {
        if let peripheral = peripheral as? CBPeripheral {
            connect(peripheral, options: options)
        }
    }
}

protocol CBCentralManagerTypeDelegate {
    func _centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheralType, advertisementData: [String : Any], rssi RSSI: NSNumber)
    func _centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheralType)
}

typealias CBCentralManagerDelegateType = CBCentralManagerDelegate & CBCentralManagerTypeDelegate
