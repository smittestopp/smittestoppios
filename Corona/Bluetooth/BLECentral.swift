import CoreBluetooth
import Foundation
import UIKit

fileprivate extension String {
    static let central = "BLECentral"
}

protocol BLECentralDelegate: class {
    func centralDidUpdateState(_ central: BLECentral)
}

class BLECentral: NSObject {
    static let BLE_ENCOUNTER_TIMEOUT: Double = 60 * 5

    var lastKnownLocation: GPSData?

    var discoveredPeripherals: [UUID: PeripheralData] = [:]
    var restoredPeripherals: [CBPeripheralType]?

    weak var delegate: BLECentralDelegate?

    lazy var manager: CBCentralManagerType = CBCentralManager(delegate: self,
                                                               queue: nil,
                                                               options: [CBCentralManagerOptionRestoreIdentifierKey:
                                                                "smittestopp.cbcentral"])
    var identifyTimer: Timer?
    var cleanTimer: Timer?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?

    private var offlineStore: OfflineStore
    private var uploader: UploaderType

    var isStarted = false

    init(offlineStore: OfflineStore,
         uploader: UploaderType) {
        self.offlineStore = offlineStore
        self.uploader = uploader
        super.init()
    }

    func start() {
        isStarted = true
        startScanning()

        if identifyTimer == nil,
            cleanTimer == nil {
            identifyTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(identifyPeripherals), userInfo: nil, repeats: true)
            cleanTimer = Timer.scheduledTimer(timeInterval: 300.0, target: self, selector: #selector(removeDisconnectedPeripherals), userInfo: nil, repeats: true)
        }
    }

    func stop() {
        identifyTimer?.invalidate()
        identifyTimer = nil
        cleanTimer?.invalidate()
        cleanTimer = nil
        stopScanning()
        isStarted = false
    }

    func startScanning() {
        guard manager.state == .poweredOn else {
            return
        }
        manager.scanForPeripherals(withServices: [BLEPeripheral.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScanning() {
        manager.stopScan()
    }

    private func beginBackgroundTaskIfNeeded() {
        guard backgroundTaskIdentifier == nil else { return }
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask {
            Logger.debug("Will end background task", tag: .central)
            self.endBackgroundTaskIfNeeded()
        }
    }

    private func endBackgroundTaskIfNeeded() {
        if let identifier = backgroundTaskIdentifier {
            backgroundTaskIdentifier = nil
            UIApplication.shared.endBackgroundTask(identifier)
        }
    }

    @objc func identifyPeripherals(_: Timer) {
        for peripheral in discoveredPeripherals.filter({ $1.uuid == nil }).mapValues(\.peripheral).values {
            manager.connect(peripheral, options: nil)
        }
    }

    @objc func removeDisconnectedPeripherals(_: Timer) {
        let timestamp = Date()
        discoveredPeripherals = discoveredPeripherals.filter {
            if timestamp.timeIntervalSince($1.lastSeen) < BLECentral.BLE_ENCOUNTER_TIMEOUT {
                return true
            }
            manager.cancelPeripheralConnection($1.peripheral)
            return false
        }
    }

    func addProximityEvent(_ event: BLEDetectionData) {
        Logger.debug("Proximity event with uuid = \(event.uuid) and rssi = \(event.rssiReading.RSSI)", tag: .central)
        offlineStore.insert(.bluetooth(.rssiReading(event)))

        beginBackgroundTaskIfNeeded()
        if UIApplication.shared.backgroundTimeRemaining > 20.0 {
            // Only trigger uploads when sufficient time remaining.
            uploader.uploadTrigger()
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLECentral: CBCentralManagerDelegateType {
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        _centralManager(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)
    }

    func _centralManager(_: CBCentralManager, didDiscover peripheral: CBPeripheralType, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        Logger.debug("Did discover peripheral \(RSSI) \(peripheral.identifier)", tag: .central)

        // a hack, we need to restructure our services/managers to avoid dependency cycles.
        (UIApplication.shared.delegate as? AppDelegate)?.heartbeatManager.sendIfNeeded()

        let timestamp = Date()
        let reading = BLERSSIReading(timestamp: timestamp, RSSI: Int(truncating: RSSI))
        if var peripheralData = discoveredPeripherals[peripheral.identifier] {
            if let uuid = peripheralData.uuid {
                let txPower = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int ?? peripheralData.txPower
                let event = BLEDetectionData(
                    uuid: uuid,
                    rssiReading: reading,
                    txPower: txPower,
                    lastKnownLocation: BLEDetectionData.Location(lastKnownLocation))
                addProximityEvent(event)
            } else {
                peripheralData.rssiReadings.append(reading)
            }
            peripheralData.lastSeen = timestamp
            discoveredPeripherals[peripheral.identifier] = peripheralData
        } else {
            discoveredPeripherals[peripheral.identifier] = PeripheralData(peripheral: peripheral,
                                                                          uuid: nil,
                                                                          lastSeen: timestamp,
                                                                          platform: nil,
                                                                          rssiReadings: [reading],
                                                                          txPower: advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int)
        }
    }

    func centralManagerDidUpdateState(_: CBCentralManager) {
        switch manager.state {
        case .poweredOn:
            Logger.debug("poweredOn", tag: .central)
            restoredPeripherals?.forEach({ manager.cancelPeripheralConnection($0) })
            restoredPeripherals = nil
            if isStarted {
                startScanning()
            }
        case .unknown:
            Logger.debug("unknown", tag: .central)
        case .resetting:
            Logger.debug("resetting", tag: .central)
        case .unsupported:
            Logger.debug("unsupported", tag: .central)
        case .unauthorized:
            Logger.debug("unauthorized", tag: .central)
        case .poweredOff:
            Logger.debug("poweredOff", tag: .central)
        @unknown default:
            Logger.debug("default... API changed?", tag: .central)
        }

        delegate?.centralDidUpdateState(self)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        _centralManager(central, didConnect: peripheral)
    }

    func _centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheralType) {
        Logger.debug("Connected to \(peripheral.identifier)", tag: .central)

        guard discoveredPeripherals[peripheral.identifier] != nil else {
            manager.cancelPeripheralConnection(peripheral)
            return
        }

        peripheral._delegate = self
        Logger.debug("Finding deviceUUID of \(peripheral.identifier)", tag: .central)
        peripheral.discoverServices([BLEPeripheral.serviceUUID])
    }

    func centralManager(_: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Logger.warning("Failed to connect to \(peripheral.identifier) with error \(error?.localizedDescription ?? "<nil>")", tag: .central)
    }

    func centralManager(_: CBCentralManager, willRestoreState dict: [String : Any]) {
        Logger.debug("Will restore state", tag: .central)
        // Disconnect after poweredOn to avoid API misuse.
        restoredPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheralType]
    }
}

// MARK: - CBPeripheralDelegate

extension BLECentral: CBPeripheralDelegateType {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        _peripheral(peripheral, didDiscoverServices: error)
    }

    func _peripheral(_ peripheral: CBPeripheralType, didDiscoverServices error: Error?) {
        Logger.debug("Discovered services \(String(describing: peripheral.services)) for \(peripheral.identifier)", tag: .central)
        if error == nil,
            let services = peripheral.services,
            services.count > 0 {
            peripheral.discoverCharacteristics([BLEPeripheral.deviceIdCharacteristicUUID], for: services[0])
        } else {
            manager.cancelPeripheralConnection(peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        _peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)
    }

    func _peripheral(_ peripheral: CBPeripheralType, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Logger.debug("Discovered characteristics for service \(service) for peripheral \(peripheral.identifier)", tag: .central)
        if error == nil,
            let characteristics = service.characteristics,
            characteristics.count > 0{
            for characteristic in characteristics {
                if characteristic.uuid == BLEPeripheral.deviceIdCharacteristicUUID {
                    peripheral.readValue(for: characteristic)
                }
            }
        } else {
            manager.cancelPeripheralConnection(peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        _peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
    }

    func _peripheral(_ peripheral: CBPeripheralType, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Logger.debug("Did update characteristic \(characteristic) for peripheral \(peripheral.identifier)", tag: .central)
        guard error == nil else {
            Logger.debug("Could not read characteristic for \(peripheral.identifier) with error \(String(describing: error))", tag: .central)
            manager.cancelPeripheralConnection(peripheral)
            return
        }

        guard var peripheralData = discoveredPeripherals[peripheral.identifier] else {
            Logger.debug("Read characteristic for unknown peripheral. Cleaned up discoveredPeripherals?", tag: .central)
            manager.cancelPeripheralConnection(peripheral)
            return
        }

        if characteristic.uuid == BLEPeripheral.deviceIdCharacteristicUUID,
            let data = characteristic.value,
            let value = String(data: data, encoding: .utf8) {
            peripheralData.uuid = value
            for reading in peripheralData.rssiReadings {
                let event = BLEDetectionData(
                    uuid: value,
                    rssiReading: reading,
                    txPower: peripheralData.txPower,
                    lastKnownLocation: BLEDetectionData.Location(lastKnownLocation))
                addProximityEvent(event)
            }
            peripheralData.rssiReadings = []
        }
        discoveredPeripherals[peripheral.identifier] = peripheralData
        manager.cancelPeripheralConnection(peripheral)
    }
}

extension BLECentral {
    struct PeripheralData {
        let peripheral: CBPeripheralType
        var uuid: String?
        var lastSeen: Date
        var platform: String?
        var rssiReadings: [BLERSSIReading] = []
        var txPower: Int?
    }
}
