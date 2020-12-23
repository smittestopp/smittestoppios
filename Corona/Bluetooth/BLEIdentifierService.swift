import Foundation

struct BLEIdentifier: Codable, Equatable {
    let expiration: Date
    let identifier: String
}

/// Provides a bluetooth identifier from the list given by the server, rotating after expiration
protocol BLEIdentifierServiceProviding {
    var identifierToUse: BLEIdentifier? { get }
    func clear()
}

protocol HasBLEIdentifierService {
    var bleIdentifierService: BLEIdentifierServiceProviding { get }
}

class BLEIdentifierService: BLEIdentifierServiceProviding {
    var apiService: ApiServiceProviding
    var localStorage: LocalStorageServiceProviding

    var expirationTime: TimeInterval

    var refreshTime: TimeInterval

    var shouldDownloadMoreIds: Bool {
        usableIds.count < 20 && !currentlyDownloadingMoreIds
    }
    var currentlyDownloadingMoreIds: Bool = false

    var identifierToUse: BLEIdentifier? {
        // use the current one if it hasn't expired
        if let currentIdentifier = currentIdentifier,
            currentIdentifier.expiration > Date() {
            return currentIdentifier
        }

        // grab a new one if needed and remove it from usable ids
        if let usableId = consumeUsableId() {
            currentIdentifier = usableId
            return usableId
        }

        // oh shiz no more usable ids, grab a random one from the expired ids
        if let expiredId = consumeExpiredId() {
            currentIdentifier = expiredId
            return expiredId
        }

        // oh crap no id available, what now?
        return nil
    }

    private var currentIdentifier: BLEIdentifier?

    private var usableIds = [String]()
    private var expiredIds = [String]()

    private var refreshTimer: Timer?

    init(apiService: ApiServiceProviding,
         localStorage: LocalStorageServiceProviding,
         expirationTime: TimeInterval,
         refreshTime: TimeInterval) {
        self.apiService = apiService
        self.localStorage = localStorage
        self.expirationTime = expirationTime
        self.refreshTime = refreshTime

        if let usableIds = localStorage.bleIdentifiers,
            !usableIds.isEmpty {
            self.usableIds.append(contentsOf: usableIds)
        }

        if let expiredIds = localStorage.expiredBleIdentifiers {
            self.expiredIds.append(contentsOf: expiredIds)
        }

        // trigger on launch
        triggerIdentifierDownloadIfNeeded()

        // trigger on refresh timer
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshTime,
                                            repeats: true,
                                            block: { _ in
            self.triggerIdentifierDownloadIfNeeded()
        })

        // trigger on login
        NotificationCenter.default.addObserver(forName: NotificationType.DeviceProvisioned,
                                               object: nil,
                                               queue: nil) { _ in
            self.triggerIdentifierDownloadIfNeeded()
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }

    func clear() {
        localStorage.bleIdentifiers = nil
        localStorage.expiredBleIdentifiers = nil
        currentIdentifier = nil
        usableIds = []
        expiredIds = []
    }

    private func saveIds(_ ids: [String]) {
        usableIds.append(contentsOf: ids)
        localStorage.bleIdentifiers = usableIds

        // reset expired ids when we get a fresh batch
        if !ids.isEmpty {
            expiredIds = [String]()
            localStorage.expiredBleIdentifiers = expiredIds
        }
    }

    private func triggerIdentifierDownloadIfNeeded() {
        if shouldDownloadMoreIds {
            currentlyDownloadingMoreIds = true
            apiService.getDeviceIds { result in
                self.currentlyDownloadingMoreIds = false

                switch result {

                case let .success(ids):
                    self.saveIds(ids)
                case .failure:
                    break
                }
            }
        }
    }

    private func consumeUsableId() -> BLEIdentifier? {
        guard let newId = usableIds.first,
            let index = usableIds.firstIndex(of: newId) else {
                return nil
        }

        usableIds.remove(at: index)
        expiredIds.append(newId)

        localStorage.bleIdentifiers = usableIds
        localStorage.expiredBleIdentifiers = expiredIds

        triggerIdentifierDownloadIfNeeded()

        return BLEIdentifier(expiration: Date().addingTimeInterval(expirationTime),
                             identifier: newId)
    }

    private func consumeExpiredId() -> BLEIdentifier? {
        guard !expiredIds.isEmpty else {
            return nil
        }

        let index = Int.random(in: 0...expiredIds.count - 1)
        let oldId = expiredIds[index]

        return BLEIdentifier(expiration: Date().addingTimeInterval(expirationTime),
                             identifier: oldId)
    }
}
