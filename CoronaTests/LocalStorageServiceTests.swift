import XCTest
@testable import Smittestopp

class LocalStorageServiceTests: XCTestCase {

    var keychainService: String!
    var userDefaults: UserDefaults!
    var user: LocalStorageService.User!

    override func setUp() {

        keychainService = #file
        userDefaults = UserDefaults(suiteName: #file)
        userDefaults.removePersistentDomain(forName: #file)

        user = LocalStorageService.User(accessToken: "accessToken",
                                        expiresOn: Utils.shared.dateFromString(str: "2020-01-01T00:00:00Z")!,
                                        phoneNumber: "1234",
                                        deviceId: "deviceId",
                                        connectionString: "connectionString")
    }

    func testKeychainMigration() {
        // empty storage
        let storage = LocalStorageService(userDefaults: userDefaults, keychainService: keychainService)
        storage.clear()
        XCTAssertNil(storage.user)
        XCTAssertNil(storage.userFromUserDefaults)

        // storage from previous app version
        storage.userFromUserDefaults = user
        XCTAssertNil(storage.user)
        XCTAssertNotNil(storage.userFromUserDefaults)
        // previous app version doesn't have this key
        userDefaults.set(false, forKey: "hasLaunchedApp")

        // new storage after app update and migration
        let newStorage = LocalStorageService(userDefaults: userDefaults, keychainService: keychainService)
        XCTAssertNil(newStorage.userFromUserDefaults)
        XCTAssertNotNil(newStorage.user)
    }

    func testKeychainClearing() {
        // fresh new version of app install without previous version
        let storage = LocalStorageService(userDefaults: userDefaults, keychainService: keychainService)
        storage.clear()
        storage.clearKeychain()
        // loggged in
        storage.hasLaunchedApp = true
        storage.user = user
        storage.hasAcceptedPrivacyPolicy = true

        // ran the new app version a second time without delete
        let sameStorage = LocalStorageService(userDefaults: userDefaults, keychainService: keychainService)
        XCTAssertNotNil(sameStorage.user)
        XCTAssertTrue(sameStorage.hasAcceptedPrivacyPolicy)
        XCTAssertTrue(sameStorage.hasLaunchedApp)

        // deleted app and installed same version, should have clear user defaults and same keychain data
        userDefaults.removePersistentDomain(forName: #file)
        let newStorage = LocalStorageService(userDefaults: userDefaults, keychainService: keychainService)

        XCTAssertNil(newStorage.user)
        XCTAssertFalse(newStorage.hasAcceptedPrivacyPolicy)
        XCTAssertTrue(newStorage.hasLaunchedApp)
    }

    func testStorageProperties() {
        let storage = LocalStorageService(userDefaults: userDefaults, keychainService: keychainService)
        storage.hasLaunchedApp = true
        storage.lastUpload = 10
        storage.logToFile = true
        storage.isTrackingEnabled = true
        storage.lastBLEUpload = 10
        storage.hasAcceptedPrivacyPolicy = true
        storage.dateOfBirth = YearMonthDay("12.02.1994")
        storage.isDateOfBirthUploaded = true
        storage.user = user

        XCTAssertNotNil(storage.dbKey)

        XCTAssertEqual(storage.hasLaunchedApp, true)
        XCTAssertEqual(storage.lastUpload, 10)
        XCTAssertEqual(storage.logToFile, true)
        XCTAssertEqual(storage.isTrackingEnabled, true)
        XCTAssertEqual(storage.lastBLEUpload, 10)
        XCTAssertEqual(storage.hasAcceptedPrivacyPolicy, true)
        XCTAssertEqual(storage.dateOfBirth, YearMonthDay("12.02.1994"))
        XCTAssertEqual(storage.isDateOfBirthUploaded, true)
        XCTAssertEqual(storage.user, user)

        storage.clearKeychain()
        XCTAssertNil(storage.user)
        XCTAssertEqual(storage.hasLaunchedApp, true)

        storage.clearUserDefaults()
        XCTAssertEqual(storage.hasLaunchedApp, false)
    }

    func testSettingDateOfBirthUpdatesUploadedFlag() {
        let storage = LocalStorageService(userDefaults: userDefaults, keychainService: keychainService)
        storage.dateOfBirth = YearMonthDay("12.02.1994")
        storage.isDateOfBirthUploaded = true

        XCTAssertEqual(storage.dateOfBirth, YearMonthDay("12.02.1994"))
        XCTAssertEqual(storage.isDateOfBirthUploaded, true)

        storage.dateOfBirth = YearMonthDay("04.04.1984")

        XCTAssertEqual(storage.dateOfBirth, YearMonthDay("04.04.1984"))
        XCTAssertEqual(storage.isDateOfBirthUploaded, false)
    }
}
