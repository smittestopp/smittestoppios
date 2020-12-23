import XCTest
@testable import Smittestopp

class LoginServiceTests: XCTestCase {

    var apiService: MockApiService!
    var localStorage: MockLocalStorageService!

    let defaultExpirationTime: TimeInterval = 15 * 60

    override func setUp() {
        apiService = MockApiService()
        localStorage = MockLocalStorageService()
    }

    func testDeviceProvisioningAttempts() {
        let loginService = LoginService(localStorage: localStorage, apiService: apiService)

        localStorage.user = .init(accessToken: "abc",
                                  expiresOn: Date().addingTimeInterval(24 * 60 * 60),
                                  phoneNumber: "",
                                  deviceId: nil,
                                  connectionString: nil)
        loginService.attemptDeviceRegistration()

        XCTAssertNotNil(localStorage.nextProvisioningAttempt)
        XCTAssertEqual(apiService.registerDeviceCalls , 1)

        loginService.attemptDeviceRegistration()

        XCTAssertEqual(apiService.registerDeviceCalls , 1)
    }
}
