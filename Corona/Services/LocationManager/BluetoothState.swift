import CoreBluetooth
import Foundation

enum BluetoothAuthorizationStatus {
    case notDetermined
    case denied
    case restricted
    case allowedAlways
}

enum BluetoothPowerState {
    case notDetermined
    case on
    case off
}

struct BluetoothState {
    let authorization: BluetoothAuthorizationStatus
    let power: BluetoothPowerState

    /// Simplified binary on/off state.
    var isEnabled: Bool {
        let powerEnabled: Bool = {
            switch power {
            case .notDetermined:
                // ignore this until we know the power state
                return true
            case .off:
                return false
            case .on:
                return true
            }
        }()

        let authEnabled:Bool = {
            switch authorization {
            case .allowedAlways:
                return true
            case .denied, .restricted, .notDetermined:
                return false
            }
        }()

        return powerEnabled && authEnabled
    }
}

@available(iOS 13.0, *)
extension CBManagerAuthorization {
    var bluetoothAuthorization: BluetoothAuthorizationStatus {
        switch self {
        case .allowedAlways:
            return .allowedAlways
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            Logger.warning("Unknown BLE authorization status: \(self)", tag: "CBManagerAuthorization")
            return .denied
        }
    }
}

extension CBPeripheralManagerAuthorizationStatus {
    var bluetoothAuthorization: BluetoothAuthorizationStatus {
        switch self {
        case .authorized:
            return .allowedAlways
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            Logger.warning("Unknown BLE authorization status: \(self)", tag: "CBPeripheralManagerAuthorizationStatus")
            return .denied
        }
    }
}
