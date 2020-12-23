import Foundation

class DependencyContainer
    : HasLoginService, HasLocalStorageService, HasBundleService, HasLocationManager,
      HasNotificationService, HasDateService, HasIoTHubService,
      HasDeviceTraitsService, HasApiService, HasUploader, HasOfflineStore, HasDateOfBirthUploader, HasBLEIdentifierService {
    let loginService: LoginServiceProviding
    let localStorage: LocalStorageServiceProviding
    let bundle: BundleServiceProviding
    let locationManager: LocationManagerProviding
    let bleIdentifierService: BLEIdentifierServiceProviding
    let notificationService: NotificationServiceProviding = NotificationService.shared
    let dateService: DateServiceProviding = DateService()
    let iotHubService: IoTHubServiceProviding
    let deviceTraits: DeviceTraitsServiceProviding = DeviceTraitsService.shared
    let apiService: ApiServiceProviding

    let uploader: UploaderType
    let offlineStore: OfflineStore
    let dateOfBirthUploader: DateOfBirthUploaderProviding

    init() {
        localStorage = LocalStorageService()

        bundle = BundleService()

        iotHubService = IoTHubService(localStorage: localStorage)

        apiService = ApiService(
            baseUrl: AppConfiguration.shared.network.backendBaseUrl,
            localStorage: localStorage,
            dateService: dateService)

        bleIdentifierService = BLEIdentifierService(
            apiService: apiService,
            localStorage: localStorage,
            expirationTime: AppConfiguration.shared.bleIdentifierService.identifierExpirationTime,
            refreshTime: AppConfiguration.shared.bleIdentifierService.identifierRefreshTime)

        loginService = LoginService(
            localStorage: localStorage,
            apiService: apiService)

        offlineStore = OfflineStore(dbKey: localStorage.dbKey)

        uploader = Uploader(
            localStorage: localStorage,
            iotHubService: iotHubService,
            loginService: loginService,
            apiService: apiService,
            bundleService: bundle,
            deviceTraitsService: deviceTraits,
            notificationService: notificationService,
            offlineStore: offlineStore)

        locationManager = LocationManager(
            appConfiguration: AppConfiguration.shared,
            localStorage: localStorage,
            offlineStore: offlineStore,
            uploader: uploader,
            bleIdentifierService: bleIdentifierService)

        dateOfBirthUploader = DateOfBirthUploader(
            localStorage: localStorage,
            apiService: apiService)
    }
}
