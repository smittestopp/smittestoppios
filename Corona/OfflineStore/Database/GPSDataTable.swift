import Foundation
import SQLite

enum Database {}

extension Database {

class GPSDataTable {
    let table = Table("gps_data")

    let gpsFromCol = Expression<Date>("fromDate")
    let gpsToCol = Expression<Date>("toDate")
    let gpsLatCol = Expression<Double>("lat")
    let gpsLonCol = Expression<Double>("lon")
    let gpsAccuracy = Expression<Double>("accuracy")
    let gpsSpeed = Expression<Double>("speed")
    let gpsAltitude = Expression<Double>("altitude")
    let gpsAltitudeAccuracy = Expression<Double>("altitude_accuracy")
    let isUploading = Expression<Bool>("isUploading")
    let uploadAttemptsCol = Expression<Int>("uploadAttempts")

    init() {
    }

    func setupSchema(_ db: Connection) throws {
        let gpsData = table.create(ifNotExists: true) { t in
            t.column(gpsFromCol, unique: true)
            t.column(gpsToCol)
            t.column(gpsLatCol)
            t.column(gpsLonCol)
            t.column(gpsAccuracy)
            t.column(gpsSpeed)
            t.column(gpsAltitude)
            t.column(gpsAltitudeAccuracy)
            t.column(isUploading)
            t.column(uploadAttemptsCol, defaultValue: 0)
        }

        try db.run(gpsData)
    }

    func insert(_ db: Connection, _ data: GPSData) throws {
        let query = table.insert(
            gpsFromCol <- data.from,
            gpsToCol <- data.to,
            gpsLatCol <- data.lat,
            gpsLonCol <- data.lon,
            gpsAccuracy <- data.accuracy,
            gpsSpeed <- data.speed,
            gpsAltitude <- data.altitude,
            gpsAltitudeAccuracy <- data.altitudeAccuracy,
            isUploading <- false)

        try db.run(query)
    }

    func update(_ db: Connection, _ data: GPSData) throws {
        let query = table
            .filter(gpsFromCol == data.from)
            .update(
                gpsToCol <- data.to,
                gpsAccuracy <- data.accuracy,
                gpsAltitudeAccuracy <- data.altitudeAccuracy
            )

        try db.run(query)
    }

    func getLatestGPSDataNotUploading(_ db: Connection) throws -> GPSData? {
        let query = table
            .select(gpsFromCol, gpsToCol, gpsLatCol, gpsLonCol, gpsAccuracy,
                    gpsSpeed, gpsAltitude, gpsAltitudeAccuracy)
            .filter(isUploading == false) // This is important!
            .order(gpsFromCol.desc) // This is important!
            .limit(1)

        for dp in try db.prepare(query) {
            let data = GPSData(
                from: dp[gpsFromCol],
                to: dp[gpsToCol],
                lat: dp[gpsLatCol],
                lon: dp[gpsLonCol],
                accuracy: dp[gpsAccuracy],
                speed: dp[gpsSpeed],
                altitude: dp[gpsAltitude],
                altitudeAccuracy: dp[gpsAltitudeAccuracy])
            return data
        }

        return nil
    }

    func getGPSDataForUpload(_ db: Connection) throws -> [GPSData] {
        var ret: [GPSData] = []

        let query = table
            .select(gpsFromCol, gpsToCol, gpsLatCol, gpsLonCol, gpsAccuracy,
                    gpsSpeed, gpsAltitude, gpsAltitudeAccuracy)
            .filter(isUploading == true)
            .order(gpsFromCol.asc)

        for dp in try db.prepare(query) {
            let data = GPSData(
                from: dp[gpsFromCol],
                to: dp[gpsToCol],
                lat: dp[gpsLatCol],
                lon: dp[gpsLonCol],
                accuracy: dp[gpsAccuracy],
                speed: dp[gpsSpeed],
                altitude: dp[gpsAltitude],
                altitudeAccuracy: dp[gpsAltitudeAccuracy])

            ret.append(data)
        }

        return ret
    }

    func deleteUploadedGPSData(_ db: Connection) throws {
        let query = table
            .select(isUploading)
            .filter(isUploading == true)
            .delete()

        try db.run(query)
    }

    func deleteGPSData(_ db: Connection, minUploadAttempts: Int) throws -> Int {
        let query = table
            .select(uploadAttemptsCol)
            .filter(uploadAttemptsCol >= minUploadAttempts)
            .delete()

        return try db.run(query)
    }

    func markForUpload(_ db: Connection, limit: Int) throws {
        // Note: This is a workaround to use a where clause instead of a directly using an order by clause
        //       in this update statement. SQLCipher seems to have a problem with that (works with plain sqlite.swift)
        let query = "UPDATE gps_data SET isUploading = 1, uploadAttempts = uploadAttempts + 1 WHERE fromDate <= " +
            "(SELECT MAX(fromDate) FROM gps_data ORDER BY fromDate ASC LIMIT \(limit))"

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

extension Database.GPSDataTable {
    struct Stats {
        let totalEvents: Int
        let eventsBeingUploaded: Int
    }
}
