import Foundation
@testable import Smittestopp

class MockLocationManager: LocationManagerProviding {
    var gpsState: GPSState = .init(authorizationStatus: .enabledAlways, isLocationServiceEnabled: true)

    var bluetoothState: BluetoothState = .init(authorization: .allowedAlways, power: .on)

    func setGPSEnabled(_: Bool) {
    }

    func setBluetoothEnabled(_: Bool) {
    }
}
