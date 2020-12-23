import CoreBluetooth
import Foundation

protocol CBPeripheralManagerType {
    var delegate: CBPeripheralManagerDelegate? { get set }
    var isAdvertising: Bool { get }
    var state: CBManagerState { get }

    @available(iOS 13.0, *)
    var authorization: CBManagerAuthorization { get }

    func startAdvertising(_ advertisementData: [String : Any]?)
    func stopAdvertising()
    func add(_ service: CBMutableService)
}

extension CBPeripheralManager: CBPeripheralManagerType { }
