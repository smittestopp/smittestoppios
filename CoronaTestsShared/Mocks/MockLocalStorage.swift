import Foundation
@testable import Smittestopp

class MockLocalStorageService: LocalStorageServiceProviding {
    var bleIdentifiers: [String]? = [String]()
    var expiredBleIdentifiers: [String]? = [String]()

    var hasLaunchedApp: Bool = true

    func clear() {
    }

    var lastUpload: TimeInterval = 0

    var logToFile: Bool = false

    var isTrackingEnabled: Bool = false

    var lastBLEUpload: TimeInterval = 0

    var hasAcceptedPrivacyPolicy: Bool = true

    var dateOfBirth: YearMonthDay? = YearMonthDay("17.05.1814")

    var isDateOfBirthUploaded: Bool = true

    var dbKey: String = "my-db-key"

    var user: LocalStorageService.User? = .init(
        accessToken: "hello", expiresOn: Date().advanced(by: 3600),
        phoneNumber: "+47 123 456 789",
        deviceId: "1234567890abcdefghijklmnopqrstuv",
        connectionString: "HostName=example.com;DeviceId=1234567890abcdefghijklmnopqrstuv;SharedAccessKey=aGVsbG8=")

    var lastHeartbeat: Date?

    var nextProvisioningAttempt: Date?
}
