import Foundation
import UIKit

// Min upload interval (5 minutes)
let MIN_UPLOAD_INTERVAL = 300.0
// Max upload interval increment (10 minutes )
let MAX_UPLOAD_INTERVAL_INCREMENT = 600.0

fileprivate extension String {
    static let uploader = "Uploader"
}

let uploadSemaphore = DispatchSemaphore(value: 1)

protocol HasUploader {
    var uploader: UploaderType { get }
}

class Uploader: NSObject, UploaderType, URLSessionDelegate {
    private var uploadInterval: Double = MIN_UPLOAD_INTERVAL
    private var isUploading = false
    private var isUploadingBLE = false
    private var hasRemindedOfUpdate = false

    private var lastUpload: TimeInterval {
        get {
            return localStorage.lastUpload
        }
        set(value) {
            localStorage.lastUpload = value
        }
    }
    private var lastBLEUpload: TimeInterval {
        get {
            return localStorage.lastBLEUpload
        }
        set(value) {
            localStorage.lastBLEUpload = value
        }
    }

    private let localStorage: LocalStorageServiceProviding
    private let iotHubService: IoTHubServiceProviding
    private let loginService: LoginServiceProviding
    private let apiService: ApiServiceProviding
    private let bundleService: BundleServiceProviding
    private let deviceTraitsService: DeviceTraitsServiceProviding
    private let notificationService: NotificationServiceProviding
    private let offlineStore: OfflineStore

    init(localStorage: LocalStorageServiceProviding,
         iotHubService: IoTHubServiceProviding,
         loginService: LoginServiceProviding,
         apiService: ApiServiceProviding,
         bundleService: BundleServiceProviding,
         deviceTraitsService: DeviceTraitsServiceProviding,
         notificationService: NotificationServiceProviding,
         offlineStore: OfflineStore) {
        self.localStorage = localStorage
        self.iotHubService = iotHubService
        self.loginService = loginService
        self.apiService = apiService
        self.bundleService = bundleService
        self.deviceTraitsService = deviceTraitsService
        self.notificationService = notificationService
        self.offlineStore = offlineStore
    }

    public func uploadTrigger() {
        uploadGPSTrigger()
        uploadBLETrigger()
    }

    public func uploadGPSTrigger() {
        Logger.debug("Checking if it is time to upload GPS.", tag: .uploader)
        let currentTime = Date().timeIntervalSince1970
        if lastUpload.distance(to: currentTime) > AppConfiguration.shared.uploader.uploadInterval {
            upload(.gps)
        } else {
            Logger.debug("Not time to upload GPS yet.", tag: .uploader)
        }
    }

    public func uploadBLETrigger() {
        Logger.debug("Checking if it is time to upload BLE.", tag: .uploader)
        let currentTime = Date().timeIntervalSince1970
        if lastBLEUpload.distance(to: currentTime) > AppConfiguration.shared.uploader.uploadInterval {
            upload(.bluetooth)
        } else {
            Logger.debug("Not time to upload BLE yet.", tag: .uploader)
        }
    }

    public func upload(_ eventType: EventType) {
        Logger.debug("Preparing upload of \(eventType).", tag: .uploader)

        // Ensure thread safety (just in case)
        uploadSemaphore.wait()

        guard !isUploading else {
            Logger.debug("Already uploading.", tag: .uploader)
            uploadSemaphore.signal()
            return
        }

        isUploading = true
        uploadSemaphore.signal()

        guard iotHubService.isStarted else {
            if !iotHubService.canStart {
                loginService.attemptDeviceRegistration()
                isUploading = false
            } else {
                // IoT Hub has credentials and hence can start,
                // but it is not started. This can happen e.g.
                // in UI tests
            }
            return
        }

        let deletedEntries = offlineStore.deleteData(ofType: eventType, minUploadAttempts: AppConfiguration.shared.uploader.MAX_UPLOAD_RETRIES)
        if deletedEntries > 0 {
            Logger.warning("Deleted \(deletedEntries) \(eventType) entries with high upload attempts", tag: .uploader)
        }

        if offlineStore.markDataForUpload(withType: eventType, limit: eventType.maxUploadEntries()) {
            let uploadData = offlineStore.getDataForUpload(withType: eventType)

            guard uploadData.count != 0 else {
                isUploading = false
                return
            }

            let eventsData: EventData
            switch uploadData {
            case let .gps(gpsData):
                let gpsEvents = gpsDataToEventDatas(gpsData: gpsData)
                eventsData = .gps(gpsEvents)
            case let .bluetooth(bleData):
                let bleEvents = bleDataToEventDatas(bleData: bleData)
                eventsData = .bluetooth(bleEvents)
            }

            let appVersion = bundleService.appVersion

            let data = DataUploadRequest(
                appVersion: appVersion,
                model: deviceTraitsService.modelName,
                events: eventsData,
                platform: "ios",
                osVersion: deviceTraitsService.systemVersion,
                jailbroken: deviceTraitsService.isJailbroken)

            if CSVFileApi.shared.enabled {
                // This API is never enabled in production
                CSVFileApi.shared.write(dataUploadRequest: data)
            }

            // If an app update is available, notify the user.
            if isUpdateAvailable() {
                notifyUpdateIsAvailable()
            }

            let stats = UploadStatisticsData(startDate: Date(), numberOfEvents: uploadData.count, eventType: eventType)
            offlineStore.insert(.stats(.uploadStarted(stats)))

            iotHubService.send(data, messageType: eventType.rawValue) { result in
                switch result {
                case .success:
                    Logger.debug("Finished uploading \(eventType) successfully.", tag: .uploader)
                    self.offlineStore.deleteUploadedData(ofType: eventType)
                    self.offlineStore.insert(.stats(.uploadSucceeded(stats)))
                    switch eventType {
                    case .gps:
                        self.lastUpload = Date().timeIntervalSince1970
                    case .bluetooth:
                        self.lastBLEUpload = Date().timeIntervalSince1970
                    }
                    self.isUploading = false

                    if uploadData.count >= eventType.maxUploadEntries() {
                        // It's very likely that not all entries were uploaded, so we try again
                        self.upload(eventType)
                    }

                    self.uploadInterval = MIN_UPLOAD_INTERVAL
                    Logger.debug("Upload interval set to \(self.uploadInterval)", tag: .uploader)
                case let .failure(error):
                    self.offlineStore.insert(.stats(.uploadFailed(stats, reason: error.localizedDescription)))
                    Logger.error("Uploading \(eventType) failed with reason: \(error.localizedDescription)", tag: .uploader)
                    self.isUploading = false

                    // Note: Both bluetooth and GPS data upload failure are increasing the upload interval.
                    self.uploadInterval = min(self.uploadInterval + self.uploadInterval / 2,
                                              self.uploadInterval + MAX_UPLOAD_INTERVAL_INCREMENT)
                    Logger.debug("Upload interval set to \(self.uploadInterval)", tag: .uploader)
                }
            }
        } else {
            Logger.warning("Could not mark \(eventType) data for upload.", tag: .uploader)
            isUploading = false
        }
    }

    private func isUpdateAvailable() -> Bool {
        let currentVersion = bundleService.appVersion
        Logger.debug("Current version \(currentVersion)", tag: .uploader)
        guard currentVersion.split(separator: ".").count == 3 else {
            return false
        }

        guard let latestVersion = iotHubService.latestVersion,
        latestVersion.split(separator: ".").count == 3 else {
            return false
        }

        return latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }

    private func notifyUpdateIsAvailable() {
        Logger.debug("Update is available!", tag: .uploader)
        if !hasRemindedOfUpdate {
            notificationService.postUpdateAvailable()
            hasRemindedOfUpdate = true
        }
    }
}

enum EventType: String {
    case gps, bluetooth

    func maxUploadEntries() -> Int {
        switch self {
        case .gps:
            return AppConfiguration.shared.uploader.MAX_GPS_ENTRIES_TO_UPLOAD_AT_ONCE
        case .bluetooth:
            return AppConfiguration.shared.uploader.MAX_BLE_ENTRIES_TO_UPLOAD_AT_ONCE
        }
    }
}
