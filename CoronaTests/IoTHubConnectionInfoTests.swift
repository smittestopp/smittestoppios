import Foundation
import XCTest
@testable import Smittestopp

class IoTHubConnectionInfoTests: XCTestCase {
    struct connectionStringCase {
        let connectionString: String
        var hostName: String?
        var deviceId: String?
        var deviceKey: String?
    }

    func testEmptyValues() {
        let config = IoTHubConnectionInfo("SharedAccessKey=;DeviceId=;HostName=")
        XCTAssertNil(config)
    }

    func testEmptyValuesWithMissingParams() {
        let config = IoTHubConnectionInfo("HostName=;123=")
        XCTAssertNil(config)
    }

    func testValueWithEqualSigns() {
        let config = IoTHubConnectionInfo("hello;DeviceId=a=b=c;what;SharedAccessKey===;HostName==")
        XCTAssertEqual(config!.deviceId, "a=b=c")
        XCTAssertEqual(config!.deviceKey, "==")
        XCTAssertEqual(config!.hostName, "=")
    }

    func testWithExtraParams() {
        let config = IoTHubConnectionInfo("DeviceId=1bd1;Something=Rare=;SharedAccessKey=key;HostName=app.test")
        XCTAssertEqual(config!.deviceId, "1bd1")
        XCTAssertEqual(config!.deviceKey, "key")
        XCTAssertEqual(config!.hostName, "app.test")
    }

    func testRealLifeValue() {
        let config = IoTHubConnectionInfo("HostName=iot-smittestopp-dev.azure-devices.net;DeviceId=d70db55e5dff4cf6bf298adfa2da613d;SharedAccessKey=bEs7b9znxIJuA2Gym8cX/TYFM8skmqAHw4mOkdpNftE=")
        XCTAssertEqual(config!.deviceId, "d70db55e5dff4cf6bf298adfa2da613d")
        XCTAssertEqual(config!.deviceKey, "bEs7b9znxIJuA2Gym8cX/TYFM8skmqAHw4mOkdpNftE=")
        XCTAssertEqual(config!.hostName, "iot-smittestopp-dev.azure-devices.net")
    }
}
