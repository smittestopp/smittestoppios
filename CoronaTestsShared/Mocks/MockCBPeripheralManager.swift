import CoreBluetooth
import Foundation

@testable import Smittestopp

class MockCBPeripheralManager: CBPeripheralManagerType {
    private var dummyPeripheralManager = CBPeripheralManager()

    var delegate: CBPeripheralManagerDelegate?
    var isAdvertising: Bool = false
    var state: CBManagerState = .poweredOff

    var services: [CBMutableService] = []

    @available(iOS 13.0, *)
    var authorization: CBManagerAuthorization {
        return .allowedAlways
    }

    func startAdvertising(_: [String : Any]?) {
        guard services.count > 0 else {
            return
        }
        isAdvertising = true
    }

    func stopAdvertising() {
        isAdvertising = false
    }

    func add(_ service: CBMutableService) {
        services.append(service)
        delegate?.peripheralManager?(dummyPeripheralManager, didAdd: service as CBService, error: nil)
    }

    func powerOn() {
        state = .poweredOn
        delegate?.peripheralManagerDidUpdateState(dummyPeripheralManager)
    }
}
