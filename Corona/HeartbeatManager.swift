import Foundation

class HeartbeatManager {
    typealias Dependencies = HasLocalStorageService & HasDateService &
        HasLocationManager & HasIoTHubService & HasBundleService & HasDeviceTraitsService
    let dependencies: Dependencies

    let minimumInterval: TimeInterval

    enum Error: Swift.Error {
        case notNeeded
        case networkUnavailable
        case unknown(IoTHubApi.Error)
    }

    var shouldSendHeartbeat: Bool {
        guard let lastHeartbeatDate = dependencies.localStorage.lastHeartbeat else {
            return true
        }

        return dependencies.dateService.now.timeIntervalSince(lastHeartbeatDate) > minimumInterval
    }

    var nextHeartbeatDate: Date {
        guard let lastHeartbeatDate = dependencies.localStorage.lastHeartbeat else {
            return dependencies.dateService.now
        }

        let desiredNextHeartbeatDate = lastHeartbeatDate.addingTimeInterval(minimumInterval)
        // ensure that the next heartbeat is always in the future
        return max(desiredNextHeartbeatDate, dependencies.dateService.now)
    }

    /// Set to true while the sync message is being sent to avoid multiple messages being sent at the same time
    private var isSending: Bool = false

    init(dependencies: Dependencies, minimumInterval: TimeInterval) {
        self.minimumInterval = minimumInterval
        self.dependencies = dependencies
    }

    func sendIfNeeded(_ completion: ((Result<Void, Error>)->Void)? = nil) {
        guard shouldSendHeartbeat, !isSending else {
            completion?(.failure(.notNeeded))
            return
        }
        send(completion)
    }

    func send(_ completion: ((Result<Void, Error>)->Void)? = nil) {
        guard dependencies.iotHubService.isStarted else {
            completion?(.failure(.networkUnavailable))
            return
        }

        let isTrackingEnabled = dependencies.localStorage.isTrackingEnabled
        let hasBluetooth = dependencies.locationManager.bluetoothState.isEnabled
        let hasLocation = dependencies.locationManager.gpsState.isEnabled

        let status: SyncEventData.Status = {
            switch (isTrackingEnabled, hasBluetooth, hasLocation) {
            case (false, _, _),
                 (true, false, false):
                return .allDisabled
            case (true, true, true):
                return .hasBluetoothAndLocation
            case (true, true, false):
                return .hasBluetoothOnly
            case (true, false, true):
                return .hasLocationOnly
            }
        }()

        let event: EventData = .sync(.init(timestamp: dependencies.dateService.now, status: status))

        let payload = DataUploadRequest(
            appVersion: dependencies.bundle.appVersion,
            model: dependencies.deviceTraits.modelName,
            events: event,
            platform: "ios",
            osVersion: dependencies.deviceTraits.systemVersion,
            jailbroken: dependencies.deviceTraits.isJailbroken)

        isSending = true

        dependencies.iotHubService.send(payload, messageType: "sync") { [weak self] result in
            self?.isSending = false

            switch result {
            case .success:
                if let strongSelf = self {
                    let now = strongSelf.dependencies.dateService.now
                    strongSelf.dependencies.localStorage.lastHeartbeat = now
                }
                completion?(.success(()))
            case let .failure(error):
                completion?(.failure(.unknown(error)))
            }
        }
    }
}
