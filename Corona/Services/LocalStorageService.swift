import Foundation
import KeychainAccess

fileprivate enum Key: String, CaseIterable {
    case hasLaunchedApp = "hasLaunchedApp"
    case lastUploadKey = "lastUpload"
    case logToFileKey = "logToFile"
    case isTrackingEnabledKey = "isTrackingEnabled"
    case userKey = "user"
    case lastBLEUploadKey = "lastBLEUpload"
    case hasAcceptedPrivacyPolicyKey = "hasAcceptedPrivacyPolicy"
    case dateOfBirthKey = "dateOfBirth"
    case isDateOfBirthUploadedKey = "isDateOfBirthUploaded"
    case lastHeartbeatKey = "lastHeartbeatKey"
    case bleIdentifiers = "bleIdentifiers"
    case expiredBleIdentifiers = "expiredBleIdentifiers"
    case nextProvisioningAttempt = "nextProvisioningAttempt"
}

protocol LocalStorageServiceProviding: class {
    func clear()

    var hasLaunchedApp: Bool { get set }

    var lastUpload: TimeInterval { get set }

    var logToFile: Bool { get set }

    var isTrackingEnabled: Bool { get set }

    var lastBLEUpload: TimeInterval { get set }

    var hasAcceptedPrivacyPolicy: Bool { get set }

    var dateOfBirth: YearMonthDay? { get set }

    var isDateOfBirthUploaded: Bool { get set }

    var dbKey: String { get }

    var user: LocalStorageService.User? { get set }

    var lastHeartbeat: Date? { get set }

    var bleIdentifiers: [String]? { get set }
    var expiredBleIdentifiers: [String]? { get set }

    var nextProvisioningAttempt: Date? { get set }
}

protocol HasLocalStorageService {
    var localStorage: LocalStorageServiceProviding { get }
}

class LocalStorageService: LocalStorageServiceProviding {
    private let defaults: UserDefaults
    private let keychain: Keychain

    init(userDefaults: UserDefaults = UserDefaults.standard, keychainService: String = "no.fhi.smittestopp.keychain") {
        defaults = userDefaults
        keychain = Keychain(service: keychainService)

        // remove keychain data if this is our first launch
        if !hasLaunchedApp {
            clearKeychain()
        }

        // Migrate data to keychain
        keychainMigration()

        hasLaunchedApp = true
    }

    func keychainMigration() {
        // check if we previously stored the user in UserDefaults
        if let user = userFromUserDefaults {
            self.user = user
            userFromUserDefaults = nil
        }
    }

    func clear() {
        clearUserDefaults()
        clearKeychain()
    }

    func clearUserDefaults() {
        Key.allCases.forEach { key in
            defaults.removeObject(forKey: key.rawValue)
        }
    }

    func clearKeychain() {
        try? keychain.removeAll()
    }

    var hasLaunchedApp: Bool {
        get {
            return defaults.bool(forKey: Key.hasLaunchedApp.rawValue)
        }
        set {
            defaults.set(newValue, forKey: Key.hasLaunchedApp.rawValue)
        }
    }

    var lastUpload: TimeInterval {
        get {
            return defaults.double(forKey: Key.lastUploadKey.rawValue)
        }
        set {
            defaults.set(newValue, forKey: Key.lastUploadKey.rawValue)
        }
    }

    var logToFile: Bool {
        get {
            return defaults.bool(forKey: Key.logToFileKey.rawValue)
        }
        set {
            defaults.set(newValue, forKey: Key.logToFileKey.rawValue)
        }
    }

    var isTrackingEnabled: Bool {
        get {
            guard defaults.value(forKey: Key.isTrackingEnabledKey.rawValue) != nil else {
                // We do Opt-out. Enable GPS & BT by default.
                return true
            }
            return defaults.bool(forKey: Key.isTrackingEnabledKey.rawValue)
        }
        set {
            defaults.set(newValue, forKey: Key.isTrackingEnabledKey.rawValue)
            NotificationCenter.default.post(name: NotificationType.TrackingConsentUpdated, object: self)
        }
    }

    var lastBLEUpload: TimeInterval {
        get {
            return defaults.double(forKey: Key.lastBLEUploadKey.rawValue)
        }
        set {
            defaults.set(newValue, forKey: Key.lastBLEUploadKey.rawValue)
        }
    }

    var hasAcceptedPrivacyPolicy: Bool {
        get {
            return defaults.bool(forKey: Key.hasAcceptedPrivacyPolicyKey.rawValue)
        }
        set {
            defaults.set(newValue, forKey: Key.hasAcceptedPrivacyPolicyKey.rawValue)
        }
    }

    var dateOfBirth: YearMonthDay? {
        get {
            guard let value = defaults.string(forKey: Key.dateOfBirthKey.rawValue) else {
                return nil
            }
            return YearMonthDay(value)
        }
        set {
            let oldValue = dateOfBirth

            defaults.set(newValue?.stringValue, forKey: Key.dateOfBirthKey.rawValue)

            if newValue != nil && oldValue != newValue {
                isDateOfBirthUploaded = false
            }
        }
    }

    var isDateOfBirthUploaded: Bool {
        get {
            return defaults.bool(forKey: Key.isDateOfBirthUploadedKey.rawValue)
        }
        set {
            defaults.set(newValue, forKey: Key.isDateOfBirthUploadedKey.rawValue)
        }
    }

    var dbKey: String {
        get {
            guard let dbKey = keychain["dbKey"] else {
                let dbKey = generateRandomString()
                keychain["dbKey"] = dbKey
                Logger.debug("Generated a new DB key", tag: #function)
                return dbKey
            }

            return dbKey
        }
    }

    struct IoTHubConfiguration: Codable {
    }

    struct User: Codable, Equatable {
        let accessToken: String
        let expiresOn: Date
        let phoneNumber: String?

        let deviceId: String?
        let connectionString: String?
    }

    var user: User? {
        get {
            let key = Key.userKey.rawValue
            guard let data = keychain[data: key] else {
                return nil
            }

            return try? JSONDecoder.standard.decode(User.self, from: data)
        }
        set {
            let key = Key.userKey.rawValue
            guard let value = newValue else {
                keychain[data: key] = nil
                return
            }

            guard let data = try? JSONEncoder.standard.encode(value) else {
                Logger.error("Failed to serialize user", tag: #function)
                return
            }

            keychain[data: key] = data
        }
    }

    var userFromUserDefaults: User? {
        get {
            let key = Key.userKey.rawValue
            guard let data = defaults.data(forKey: key) else {
                return nil
            }

            return try? JSONDecoder.standard.decode(User.self, from: data)
        }
        set {
            let key = Key.userKey.rawValue
            guard let value = newValue else {
                defaults.set(nil, forKey: key)
                return
            }

            guard let data = try? JSONEncoder.standard.encode(value) else {
                Logger.error("Failed to serialize user", tag: #function)
                return
            }

            defaults.set(data, forKey: key)
        }
    }

    var lastHeartbeat: Date? {
        get {
            return defaults.value(forKey: Key.lastHeartbeatKey.rawValue) as? Date
        }
        set {
            defaults.set(newValue, forKey: Key.lastHeartbeatKey.rawValue)
        }
    }

    var bleIdentifiers: [String]? {
        get {
            return defaults.value(forKey: Key.bleIdentifiers.rawValue) as? [String]
        }
        set {
            defaults.set(newValue, forKey: Key.bleIdentifiers.rawValue)
        }
    }

    var expiredBleIdentifiers: [String]? {
        get {
            return defaults.value(forKey: Key.expiredBleIdentifiers.rawValue) as? [String]
        }
        set {
            defaults.set(newValue, forKey: Key.expiredBleIdentifiers.rawValue)
        }
    }

    var nextProvisioningAttempt: Date? {
        get {
            return defaults.value(forKey: Key.nextProvisioningAttempt.rawValue) as? Date
        }
        set {
            defaults.set(newValue, forKey: Key.nextProvisioningAttempt.rawValue)
        }
    }
}
