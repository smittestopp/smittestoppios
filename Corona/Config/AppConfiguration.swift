import Foundation

enum AppConfigurationTarget: String, Codable {
    case releaseDev
    case dev
    case prod
    case unitTest
}

struct AppConfiguration {
    init(_ target: AppConfigurationTarget) {
        switch target {
        case .releaseDev:
            self = .releaseDev
            Logger.debug("Running prod environment with dev settings", tag: "AppConfiguration")
        case .dev:
            Logger.debug("Running dev environment", tag: "AppConfiguration")
            self = .dev
        case .prod:
            Logger.debug("Running prod environment", tag: "AppConfiguration")
            self = .prod
        case .unitTest:
            Logger.debug("Running unitTest environment", tag: "AppConfiguration")
            self = .unitTest
        }
    }

    static let shared: AppConfiguration = AppConfiguration(Environment.appConfigurationTarget)

    static var releaseDev = AppConfiguration(network: .dev,
                                             azureIdentityConfig: .dev,
                                             locationManager: .prod,
                                             uploader: .prod,
                                             heartbeatManager: .prod,
                                             bleIdentifierService: .prod)

    static var dev = AppConfiguration(network: .dev,
                                      azureIdentityConfig: .dev,
                                      locationManager: .dev,
                                      uploader: .dev,
                                      heartbeatManager: .dev,
                                      bleIdentifierService: .dev)

    static var prod = AppConfiguration(network: .prod,
                                       azureIdentityConfig: .prod,
                                       locationManager: .prod,
                                       uploader: .prod,
                                       heartbeatManager: .prod,
                                       bleIdentifierService: .prod)

    static var unitTest = AppConfiguration(network: .dev,
                                           azureIdentityConfig: .dev,
                                           locationManager: .unitTest,
                                           uploader: .unitTest,
                                           heartbeatManager: .dev,
                                           bleIdentifierService: .dev)

    private init(network: AppConfiguration.Network,
                 azureIdentityConfig: AppConfiguration.AzureIdentityConfig,
                 locationManager: AppConfiguration.LocationManager,
                 uploader: AppConfiguration.Uploader,
                 heartbeatManager: AppConfiguration.HeartbeatManager,
                 bleIdentifierService: AppConfiguration.BLEIdentifierService) {

        self.network = network
        self.azureIdentityConfig = azureIdentityConfig
        self.locationManager = locationManager
        self.uploader = uploader
        self.heartbeatManager = heartbeatManager
        self.bleIdentifierService = bleIdentifierService
    }

    var appStoreAppId = "id123456789"
    var appStoreWebUrl: String {
        return "https://apps.apple.com/app/apple-store/\(appStoreAppId)"
    }

    // MARK: Network

    struct Network {
        let backendBaseUrl: String

        static let dev = Network(backendBaseUrl: "https://backend.base.url.dev.no/")
        static let prod = Network(backendBaseUrl: "https://backend.base.url.prod.no/")
    }

    // MARK: Login service config

    struct AzureIdentityConfig {
        let kTenantName: String
        let kAuthorityHostName: String
        /// The ClientId should also be registered as a URL Scheme in Info.plist for redirect to work.
        /// in a format `msal<my-client-id>`
        let kClientID: String
        let kSignupOrSigninPolicy: String
        let kScopes: [String]

        static let dev: AzureIdentityConfig = .init(
            kTenantName: "login.tenant.com",
            kAuthorityHostName: "login.host.com",
            kClientID: "1234567-abcd-cdef-ghif-123456789000",
            kSignupOrSigninPolicy: "phone_SOSP",
            kScopes: ["https://backend.com/write"])
        static let prod: AzureIdentityConfig = .init(
            kTenantName: "login.tenant.com",
            kAuthorityHostName: "login.host.com",
            kClientID: "1234567-abcd-cdef-ghif-123456789000",
            kSignupOrSigninPolicy: "phone_SOSP",
            kScopes: ["https://backend.com/write"])
    }

    // MARK: Location Manager config

    struct LocationManager {
        let PAUSE_GPS_IDLE_PERIOD: Double
        let PAUSE_GPS_REGION_RADIUS: Double

        static let dev = LocationManager(
            PAUSE_GPS_IDLE_PERIOD: 60 * 1, // 1 minute for debugging purposes.
            PAUSE_GPS_REGION_RADIUS: 40.0
        )
        static let prod = LocationManager(
            PAUSE_GPS_IDLE_PERIOD: 60 * 5,
            PAUSE_GPS_REGION_RADIUS: 40.0
        )
        static let unitTest = LocationManager(
            PAUSE_GPS_IDLE_PERIOD: 1,
            PAUSE_GPS_REGION_RADIUS: 40.0
        )
    }

    // MARK: Uploader config

    struct Uploader {
        let uploadInterval: Double
        /// Max number of GPS database entries that we will be uploaded at once.
        let MAX_GPS_ENTRIES_TO_UPLOAD_AT_ONCE: Int
        /// Max number of BLE database entries to upload at once.
        let MAX_BLE_ENTRIES_TO_UPLOAD_AT_ONCE: Int
        /// Max number of times GPS database entries upload will be retried.
        let MAX_UPLOAD_RETRIES: Int

        static let dev = Uploader(
            uploadInterval: 60 * 1, // Every minute for debugging
            MAX_GPS_ENTRIES_TO_UPLOAD_AT_ONCE: 600,
            MAX_BLE_ENTRIES_TO_UPLOAD_AT_ONCE: 600,
            MAX_UPLOAD_RETRIES: 10
        )
        static let prod = Uploader(
            uploadInterval: 60 * 10,
            MAX_GPS_ENTRIES_TO_UPLOAD_AT_ONCE: 600,
            MAX_BLE_ENTRIES_TO_UPLOAD_AT_ONCE: 600,
            MAX_UPLOAD_RETRIES: 40
        )
        static let unitTest = Uploader(
            uploadInterval: 1,
            MAX_GPS_ENTRIES_TO_UPLOAD_AT_ONCE: 600,
            MAX_BLE_ENTRIES_TO_UPLOAD_AT_ONCE: 600,
            MAX_UPLOAD_RETRIES: 40
        )
    }

    // MARK: Heartbeat Manager config

    struct HeartbeatManager {
        let minimumInterval: Double

        static let dev = HeartbeatManager(
            minimumInterval: 1 * 60
        )
        static let prod = HeartbeatManager(
            minimumInterval: 1 * 60
        )
    }

    struct BLEIdentifierService {
        let identifierExpirationTime: TimeInterval
        let identifierRefreshTime: TimeInterval

        static let prod = BLEIdentifierService(
            identifierExpirationTime: 15 * 60, // 15 minutes
            identifierRefreshTime: 60 * 60 // one hour
        )

        static let dev = BLEIdentifierService(
            identifierExpirationTime: 1 * 60, // 1 minute
            identifierRefreshTime: 10 * 60 // 10 minutes
        )
    }

    // MARK: configs
    let network: AppConfiguration.Network
    let azureIdentityConfig: AppConfiguration.AzureIdentityConfig
    let locationManager: AppConfiguration.LocationManager
    let uploader: AppConfiguration.Uploader
    let heartbeatManager: AppConfiguration.HeartbeatManager
    let bleIdentifierService: AppConfiguration.BLEIdentifierService
}
