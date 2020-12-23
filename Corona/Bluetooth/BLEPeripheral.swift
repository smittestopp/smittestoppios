import CoreBluetooth
import CoreLocation
import Foundation
import UIKit

fileprivate extension String {
    static let peripheral = "BLEPeripheral"
}

protocol BLEPeripheralDelegate: class {
    func peripheralDidUpdateState(_ peripheral: BLEPeripheral)
}

class BLEPeripheral: NSObject {

    static let serviceUUID = CBUUID(string: "e45c1747-a0a4-44ab-8c06-a956df58d93a")
    static let deviceIdCharacteristicUUID = CBUUID(string: "64b81e3c-d60c-4f08-8396-9351b04f7591")
    static let beaconUUID = UUID(uuidString: "1283d24a-da80-440a-aa8c-6fdce884b107")!
    static let beaconMajor: CLBeaconMajorValue = 123
    static let beaconMinor: CLBeaconMinorValue = 456

    weak var delegate: BLEPeripheralDelegate?

    lazy var manager: CBPeripheralManagerType = CBPeripheralManager(
        delegate: self,
        queue: nil,
        options: [CBPeripheralManagerOptionRestoreIdentifierKey: "identifier.key"]
    )

    private var localStorage: LocalStorageServiceProviding
    private var bleIdentifierService: BLEIdentifierServiceProviding

    private var isStarted = false

    init(localStorage: LocalStorageServiceProviding, bleIdentifierService: BLEIdentifierServiceProviding) {
        self.localStorage = localStorage
        self.bleIdentifierService = bleIdentifierService
        super.init()
    }

    func start() {
        isStarted = true
        startAdvertising()
    }

    func stop() {
        manager.stopAdvertising()
        isStarted = false
    }

    func startAdvertising() {
        guard manager.state == .poweredOn else {
            return
        }

        guard isStarted else {
            return
        }

        let service = CBMutableService(type: BLEPeripheral.serviceUUID,
                                       primary: true)
        let deviceCharacteristic = CBMutableCharacteristic(
            type: BLEPeripheral.deviceIdCharacteristicUUID,
            properties: .read,
            value: nil,
            permissions: .readable
        )
        service.characteristics = [deviceCharacteristic]
        manager.add(service)
    }
}

// MARK: CBPeripheralManagerDelegate
extension BLEPeripheral: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_: CBPeripheralManager) {
        switch manager.state {
        case .poweredOn:
            Logger.debug("poweredOn", tag: .peripheral)
            startAdvertising()
        case .unknown:
            Logger.debug("unknown", tag: .peripheral)
        case .resetting:
            Logger.debug("resetting", tag: .peripheral)
        case .unsupported:
            Logger.debug("unsupported", tag: .peripheral)
        case .unauthorized:
            Logger.debug("unauthorized", tag: .peripheral)
        case .poweredOff:
            Logger.debug("poweredOff", tag: .peripheral)
        default:
            Logger.debug("default... API changed?", tag: .peripheral)
        }

        delegate?.peripheralDidUpdateState(self)
    }

    func peripheralManager(_: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        Logger.debug("Added service \(service)", tag: #function)
        guard error == nil else {
            Logger.warning("didAdd service error: \(String(describing: error))", tag: .peripheral)
            return
        }
        Logger.debug("Started advertising service \(service.uuid)", tag: .peripheral)
        manager.startAdvertising([CBAdvertisementDataLocalNameKey: UIDevice.current.name, CBAdvertisementDataServiceUUIDsKey: [service.uuid]])
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard request.characteristic.uuid == BLEPeripheral.deviceIdCharacteristicUUID else {
            peripheral.respond(to: request, withResult: .readNotPermitted)
            return
        }

        guard let bluetoothId = bleIdentifierService.identifierToUse,
            let bluetoothIdData = bluetoothId.identifier.data(using: .utf8) else {
            peripheral.respond(to: request, withResult: .unlikelyError)
            return
        }

        request.value = bluetoothIdData
        peripheral.respond(to: request, withResult: .success)
    }

    func peripheralManager(_: CBPeripheralManager, willRestoreState _: [String : Any]) {
        Logger.debug("willRestoreState", tag: .peripheral)
    }
}
