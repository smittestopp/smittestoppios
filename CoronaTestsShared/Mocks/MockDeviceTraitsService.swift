import Foundation
@testable import Smittestopp

class MockDeviceTraitsService: DeviceTraitsServiceProviding {
    var isSmall: Bool = false
    var hasNotch: Bool = true
    var modelName: String = "MockPhone1,1"
    var systemVersion: String = "444.222"
    var isSimulator: Bool = false
    var isJailbroken: Bool = false
}
