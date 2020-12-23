import Foundation

fileprivate extension String {
    static let iot = "IoTHubService"
}

protocol IoTHubServiceProviding: class {
    var isStarted: Bool { get }
    var canStart: Bool { get }
    var latestVersion: String? { get }

    func start()
    func stop()
    func send(_ data: DataUploadRequest, messageType: String, _ completion: ((Result<Void, IoTHubApi.Error>)->Void)?)
}

protocol HasIoTHubService {
    var iotHubService: IoTHubServiceProviding { get }
}

class IoTHubService: IoTHubServiceProviding {
    @Atomic private(set) var isStarted: Bool = false

    var canStart: Bool {
        return localStorage.user?.connectionString != nil
    }

    var latestVersion: String?

    static let AccessRevoked = Notification.Name("IoTHubApi.AccessRevoked")

    private let queue = DispatchQueue(label: "no.fhi.smittestopp.iothub")
    /// IoT hub handle
    private var iotHub: IoTHubApi?
    /// Timer for message polls
    private var pollTimer: DispatchSourceTimer?
    /// How often to poll for cloud-to-device messages. Should not be lower than 25 minutes.
    static let pollingInterval: TimeInterval = 25 * 60

    private let localStorage: LocalStorageServiceProviding

    init(localStorage: LocalStorageServiceProviding) {
        self.localStorage = localStorage
    }

    func start() {
        guard let connectionString = localStorage.user?.connectionString else {
            return
        }

        guard let iotHub = IoTHubApi(connectionString) else {
            Logger.error("Failed to create IoT handle", tag: .iot)
            return
        }

        self.iotHub = iotHub

        iotHub.updatedVersionAvailableCallback = { [weak self] version in
            DispatchQueue.main.async {
                self?.updatedVersionAvailable(version)
            }
        }

        iotHub.badCredentialsCallback = { [weak self] in
            DispatchQueue.main.async {
                self?.accessRevoked()
            }
        }

        isStarted = true

        pollTimer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        pollTimer?.setEventHandler {
            self.poll()
        }
        let interval = IoTHubService.pollingInterval
        pollTimer?.schedule(deadline: .now() + interval, repeating: interval)
        pollTimer?.activate()
    }

    func stop() {
        isStarted = false
        pollTimer?.cancel()
        pollTimer = nil
    }

    private func poll() {
        guard isStarted else { return }

        let start = DispatchTime.now()

        iotHub?.runOnce()

        let end = DispatchTime.now()
        let elapsedMs = (end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
        if elapsedMs > 500 {
            Logger.warning("Event loop took \(elapsedMs)ms", tag: .iot)
        } else if elapsedMs > 200 {
            Logger.debug("Event loop took \(elapsedMs)ms", tag: .iot)
        }
    }

    private func updatedVersionAvailable(_ version: String) {
        Logger.debug("Received IoTHub message with version \(version).", tag: .iot)
        latestVersion = version
    }

    private func accessRevoked() {
        guard localStorage.user != nil else {
            return
        }
        stop()
        NotificationCenter.default.post(name: IoTHubService.AccessRevoked, object: nil)
    }

    func send(_ data: DataUploadRequest, messageType: String, _ completion: ((Result<Void, IoTHubApi.Error>)->Void)? = nil) {
        guard let iotHub = iotHub else {
            completion?(.failure(.notStarted))
            return
        }

        queue.async {
            let jsonData: Data
            do {
                jsonData = try JSONEncoder.standard.encode(data)
            } catch {
                Logger.error("Unable to encode DataUploadRequest to JSON: \(error.localizedDescription)", tag: .iot)
                completion?(.failure(.dataCorrupt))
                return
            }

            iotHub.send(jsonData, messageType: messageType) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        Logger.debug("Message sent.", tag: .iot)
                    case let .failure(error):
                        Logger.debug("Failed to sent message: \(error)", tag: .iot)
                    }

                    completion?(result)
                }
            }
        }
    }
}
