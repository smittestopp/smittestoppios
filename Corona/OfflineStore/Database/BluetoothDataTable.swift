import Foundation
import SQLite

extension Database {

class BluetoothDataTable {
    let table = Table("bluetooth_data")

    let bleTimestampCol = Expression<Date>("timestamp")
    let bleUuidCol = Expression<String>("uuid")
    let bleRssiCol = Expression<Int>("rssi")
    let bleTxPowerCol = Expression<Int?>("txPower")
    let locationLatitudeCol = Expression<Double?>("locationLatitude")
    let locationLongitudeCol = Expression<Double?>("locationLongitude")
    let locationAccuracyCol = Expression<Double?>("locationAccuracy")
    let locationTimestampCol = Expression<Date?>("locationTimestamp")
    let isUploading = Expression<Bool>("isUploading")
    let uploadAttemptsCol = Expression<Int>("uploadAttempts")

    init() {
    }

    func setupSchema(_ db: Connection) throws {
        let gpsData = table.create(ifNotExists: true) { t in
            t.column(bleTimestampCol)
            t.column(bleUuidCol)
            t.column(bleRssiCol)
            t.column(bleTxPowerCol)
            t.column(locationLatitudeCol)
            t.column(locationLongitudeCol)
            t.column(locationAccuracyCol)
            t.column(locationTimestampCol)
            t.column(isUploading)
            t.column(uploadAttemptsCol, defaultValue: 0)
        }

        try db.run(gpsData)
    }

    func insert(_ db: Connection, _ data: BLEDetectionData) throws {
        let query = table.insert(
            bleTimestampCol <- data.rssiReading.timestamp,
            bleUuidCol <- data.uuid,
            bleRssiCol <- data.rssiReading.RSSI,
            bleTxPowerCol <- data.txPower,
            locationLatitudeCol <- data.lastKnownLocation?.latitude,
            locationLongitudeCol <- data.lastKnownLocation?.longitude,
            locationAccuracyCol <- data.lastKnownLocation?.accuracy,
            locationTimestampCol <- data.lastKnownLocation?.timestamp,
            isUploading <- false)

        try db.run(query)
    }

    func markForUpload(_ db: Connection, limit: Int) throws {
        // Note: This is a workaround to use a where clause instead of a directly using an order by clause
        //       in this update statement. SQLCipher seems to have a problem with that (works with plain sqlite.swift)
        let query = "UPDATE bluetooth_data SET isUploading = 1, uploadAttempts = uploadAttempts + 1 WHERE timestamp <= " +
            "(SELECT MAX(timestamp) FROM bluetooth_data ORDER BY timestamp ASC LIMIT \(limit))"

        try db.run(query)
    }

    func getBLEDataForUpload(_ db: Connection) throws -> [BLEDetectionData] {
        var ret: [BLEDetectionData] = []

        let query = table
            .filter(isUploading == true)
            .order(bleUuidCol.asc, bleTimestampCol.asc)

        for dp in try db.prepare(query) {
            let rssi = BLERSSIReading(timestamp: dp[bleTimestampCol], RSSI: dp[bleRssiCol])
            let lastKnownLocation: BLEDetectionData.Location? = {
                guard
                    let lat = dp[locationLatitudeCol],
                    let long = dp[locationLongitudeCol],
                    let accuracy = dp[locationAccuracyCol],
                    let timestamp = dp[locationTimestampCol]
                else {
                    return nil
                }
                return BLEDetectionData.Location(
                    latitude: lat,
                    longitude: long,
                    accuracy: accuracy,
                    timestamp: timestamp)
            }()

            let data = BLEDetectionData(
                uuid: dp[bleUuidCol],
                rssiReading: rssi,
                txPower: dp[bleTxPowerCol],
                lastKnownLocation: lastKnownLocation)
            ret.append(data)
        }

        return ret
    }

    func deleteBLEData(_ db: Connection, minUploadAttempts: Int) throws -> Int {
        let query = table
            .select(uploadAttemptsCol)
            .filter(uploadAttemptsCol >= minUploadAttempts)
            .delete()

        return try db.run(query)
    }

    func deleteUploadedBLEData(_ db: Connection) throws {
        let query = table
            .select(isUploading)
            .filter(isUploading == true)
            .delete()
        try db.run(query)
    }

    func getStats(_ db: Connection) throws -> Stats {
        let total = try db.scalar(table.count)

        let uploading = try db.scalar(table
            .filter(isUploading == true)
            .count)

        return Stats(totalEvents: total, eventsBeingUploaded: uploading)
    }
}

}

extension Database.BluetoothDataTable {
    struct Stats {
        let totalEvents: Int
        let eventsBeingUploaded: Int
    }
}
