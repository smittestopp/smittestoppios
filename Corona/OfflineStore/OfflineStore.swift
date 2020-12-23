import Foundation
import SQLite

fileprivate extension String {
    static let store = "OfflineStore"
}

protocol HasOfflineStore {
    var offlineStore: OfflineStore { get }
}

class OfflineStore {
    private let dbFilePath: String
    private let dbKey: String
    private var db: Connection?

    private let gpsDataTable = Database.GPSDataTable()
    private let uploadStatsTable = Database.UploadStatsTable()
    private let bluetoothDataTable = Database.BluetoothDataTable()

    var isOpen: Bool { return db != nil }
    var accessRevokedObserver: NSObjectProtocol?

    init(dbFileName: String = "offline_store_v2.2.sqlite",
         dbKey: String) {
        dbFilePath = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(dbFileName).relativePath
        self.dbKey = dbKey
        openDb()

        accessRevokedObserver = NotificationCenter.default.addObserver(forName: IoTHubService.AccessRevoked, object: nil, queue: nil) { _ in
            self.removeAllData()
        }
    }

    private func openDb() {
        guard db == nil else { return }

        do {
            db = try Connection(dbFilePath)

            do {
                try db?.key(dbKey)
            } catch let error {
                Logger.error("Could not decrypt DB file: \(error). Creating a new DB file", tag: .store)
                // Remove the old DB file
                try! FileManager.default.removeItem(atPath: dbFilePath)
                // Reconnect to the file
                db = try Connection(dbFilePath)
                try db?.key(dbKey)
            }

            try setupSchema()
        } catch let Result.error(message, _, statement) {
            Logger.error("Expression error: \(message), in \(String(describing: statement))", tag: .store)
        } catch let error {
            Logger.error("Unknown exception: \(error)", tag: .store)
        }
    }

    // MARK: Internal helpers

    /// Helper function that catches and logs database errors
    private func exec(_ operation: () throws -> Void) rethrows {
        do {
            try operation()
        } catch let Result.error(message, code, statement) {
            Logger.error("Expression error: \(message), in \(String(describing: statement))", tag: .store)
            throw Result.error(message: message, code: code, statement: statement)
        } catch let error {
            Logger.error("Unknown exception: \(error)", tag: .store)
            throw error
        }
    }

    private func exec(_ query: Insert) throws {
        try exec {
            try db?.run(query)
        }
    }

    private func exec(_ query: Update) throws {
        try exec {
            try db?.run(query)
        }
    }

    private func exec(_ query: Delete) throws {
        try exec {
            try db?.run(query)
        }
    }

    private func setupSchema() throws {
        guard let db = db else {
            assertionFailure()
            return
        }

        try gpsDataTable.setupSchema(db)
        try uploadStatsTable.setupSchema(db)
        try bluetoothDataTable.setupSchema(db)
    }

    // MARK: Public methods

    func removeAllData() {
        db = nil

        do {
            try FileManager.default.removeItem(atPath: dbFilePath)
        } catch {
            Logger.error("Failed to delete database file: \(error)", tag: .store)
        }

        openDb()
    }

    func insert(_ event: StorableEvent) {
        guard let db = db else {
            assertionFailure()
            return
        }

        try? exec {
            switch event {
            case let .gps(gpsEvent):
                switch gpsEvent {
                case let .insert(data):
                    try gpsDataTable.insert(db, data)
                    Logger.debug("Inserted GPS datapoint", tag: .store)
                case let .update(data):
                    try gpsDataTable.update(db, data)
                    Logger.debug("Update GPS datapoint", tag: .store)
                case let .stationary(data):
                    // TODO:
                    _ = data
                    break
                }

            case let .stats(stats):
                try uploadStatsTable.insert(db, stats)
                Logger.debug("Inserted stats \(stats)", tag: .store)

            case let .bluetooth(bleEvent):
                switch bleEvent {
                case let .rssiReading(data):
                    try bluetoothDataTable.insert(db, data)
                    Logger.debug("Inserted Bluetooth datapoint", tag: .store)
                }
            }
        }
    }

    func deleteUploadedData(ofType eventType: EventType) {
        guard let db = db else {
            assertionFailure()
            return
        }

        try? exec {
            switch eventType {
            case .gps:
                try gpsDataTable.deleteUploadedGPSData(db)
            case .bluetooth:
                try bluetoothDataTable.deleteUploadedBLEData(db)
            }
        }
    }

    func deleteData(ofType eventType: EventType, minUploadAttempts: Int) -> Int {
        guard let db = db else {
            assertionFailure()
            return 0
        }

        var result: Int = 0
        try? exec {
            switch eventType {
            case .gps:
                result = try gpsDataTable.deleteGPSData(db, minUploadAttempts: minUploadAttempts)
            case .bluetooth:
                result = try bluetoothDataTable.deleteBLEData(db, minUploadAttempts: minUploadAttempts)
            }
        }
        return result
    }

    func markDataForUpload(withType eventType: EventType, limit: Int) -> Bool {
        guard let db = db else {
            assertionFailure()
            return false
        }

        do {
            try exec {
                switch eventType {
                case .gps:
                    try gpsDataTable.markForUpload(db, limit: limit)
                case .bluetooth:
                    try bluetoothDataTable.markForUpload(db, limit: limit)
                }
            }
            return true
        } catch {
            return false
        }
    }

    func getBLEDataForUpload() -> [BLEDetectionData] {
        guard let db = db else {
            assertionFailure()
            return []
        }

        var result: [BLEDetectionData] = []

        try? exec {
            result = try bluetoothDataTable.getBLEDataForUpload(db)
        }

        return result
    }

    func getGPSDataForUpload() -> [GPSData] {
        guard let db = db else {
            assertionFailure()
            return []
        }

        var result: [GPSData] = []

        try? exec {
            result = try gpsDataTable.getGPSDataForUpload(db)
        }

        return result
    }

    func getLatestGPSDataNotUploading() -> GPSData? {
        var result: GPSData?

        guard let db = db else {
            assertionFailure()
            return result
        }

        try? exec {
            result = try gpsDataTable.getLatestGPSDataNotUploading(db)
        }

        return result
    }

    func getDataForUpload(withType eventType: EventType) -> UploadData {
        var result: UploadData = .gps([])

        guard let db = db else {
            assertionFailure()
            return result
        }

        try? exec {
            switch eventType {
            case .gps:
                result = try .gps(gpsDataTable.getGPSDataForUpload(db))
            case .bluetooth:
                result = try .bluetooth(bluetoothDataTable.getBLEDataForUpload(db))
            }

        }

        return result
    }

    func getUploadStats() -> UploadStats? {
        guard let db = db else {
            assertionFailure()
            return nil
        }

        var gps: Database.GPSDataTable.Stats?
        try? exec {
            gps = try gpsDataTable.getStats(db)
        }

        var ble: Database.BluetoothDataTable.Stats?
        try? exec {
            ble = try bluetoothDataTable.getStats(db)
        }

        var lastUpload: Database.UploadStatsTable.LastUpload?
        try? exec {
            lastUpload = try uploadStatsTable.getLastUpload(db)
        }

        return UploadStats(
            totalNumberOfGPSEvents: gps?.totalEvents ?? 0,
            numberOfUploadingGPSEvents: gps?.eventsBeingUploaded ?? 0,
            totalNumberOfBLEEvents: ble?.totalEvents ?? 0,
            numberOfUploadingBLEEvents: ble?.eventsBeingUploaded ?? 0,
            lastAttempt: lastUpload?.started,
            lastSuccessfull: lastUpload?.success)
    }

    func getUploadLogs() -> [Database.UploadStatsTable.UploadLogEntry] {
        guard let db = db else {
            assertionFailure()
            return []
        }

        var logs: [Database.UploadStatsTable.UploadLogEntry] = []
        try? exec {
            logs = try uploadStatsTable.getLogs(db)
        }
        return logs
    }

    var databaseSizeInBytes: UInt64 {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: dbFilePath)
            return attr[FileAttributeKey.size] as? UInt64 ?? 0
        } catch {
            Logger.error("Failed to get db file stats", tag: .store)
            return 0
        }
    }
}

extension OfflineStore {
    struct UploadStats {
        let totalNumberOfGPSEvents: Int
        let numberOfUploadingGPSEvents: Int
        let totalNumberOfBLEEvents: Int
        let numberOfUploadingBLEEvents: Int
        let lastAttempt: Date?
        let lastSuccessfull: Date?
    }
}

extension OfflineStore {
    enum UploadData {
        case gps([GPSData])
        case bluetooth([BLEDetectionData])

        var count: Int {
            get {
                switch self {
                case let .gps(data):
                    return data.count
                case let .bluetooth(data):
                    return data.count
                }
            }
        }
    }
}
