import Foundation
import SQLite

extension Database {

class UploadStatsTable {
    let table = Table("stats")

    let timestampCol = Expression<Date>("timestamp")
    let eventTypeCol = Expression<String>("eventType")
    let startDateCol = Expression<Date>("startDate")
    let numberOfEventsCol = Expression<Int>("numberOfEventsCol")
    let messageCol = Expression<String?>("message")
    let dataTypeCol = Expression<String>("dataType")

    init() {
    }

    func setupSchema(_ db: Connection) throws {
        let gpsData = table.create(ifNotExists: true) { t in
            t.column(timestampCol)
            t.column(eventTypeCol)
            t.column(startDateCol)
            t.column(numberOfEventsCol)
            t.column(messageCol)
            t.column(dataTypeCol)
        }

        try db.run(gpsData)
    }

    func insert(_ db: Connection, _ data: StorableStatistic) throws {
        let query: Insert

        switch data {
        case let .uploadStarted(data):
            query = table.insert(
                timestampCol <- Date(),
                eventTypeCol <- "started",
                startDateCol <- data.startDate,
                numberOfEventsCol <- data.numberOfEvents,
                messageCol <- nil,
                dataTypeCol <- data.eventType.rawValue)
        case let .uploadSucceeded(data):
            query = table.insert(
                timestampCol <- Date(),
                eventTypeCol <- "success",
                startDateCol <- data.startDate,
                numberOfEventsCol <- data.numberOfEvents,
                messageCol <- nil,
                dataTypeCol <- data.eventType.rawValue)
        case let .uploadFailed(data, reason):
            query = table.insert(
                timestampCol <- Date(),
                eventTypeCol <- "failure",
                startDateCol <- data.startDate,
                numberOfEventsCol <- data.numberOfEvents,
                messageCol <- reason,
                dataTypeCol <- data.eventType.rawValue)
        }

        try db.run(query)
    }

    func getLastUpload(_ db: Connection) throws -> LastUpload? {
        let started = try db.pluck(table
            .select(startDateCol)
            .filter(eventTypeCol == "started")
            .order(timestampCol.desc)
            .limit(1))

        guard let lastStartedDate = started?[startDateCol] else {
            return nil
        }

        let success = try db.pluck(table
            .select(startDateCol)
            .filter(eventTypeCol == "success")
            .order(timestampCol.desc)
            .limit(1))

        guard let lastSuccessDate = success?[startDateCol] else {
            return nil
        }

        return LastUpload(started: lastStartedDate, success: lastSuccessDate)
    }

    func getLogs(_ db: Connection) throws -> [UploadLogEntry] {
        let query = table
            .select(
                timestampCol, eventTypeCol, startDateCol,
                numberOfEventsCol, messageCol,
                dataTypeCol)
            .order(timestampCol.desc)
            .limit(200)

        var result: [UploadLogEntry] = []

        for row in try db.prepare(query) {
            let entry = UploadLogEntry(
                date: row[timestampCol],
                startDate: row[startDateCol],
                type: { () -> UploadLogEntry.EntryType in
                    switch row[eventTypeCol] {
                    case "started": return .started
                    case "success": return .succeeded
                    case "failure": return .failed
                    default:
                        assertionFailure()
                        return .failed
                    }
            }(),
                numberOfEvents: row[numberOfEventsCol],
                message: row[messageCol],
                dataType: { () -> EventType in
                    switch row[dataTypeCol] {
                    case "gps": return .gps
                    case "bluetooth": return .bluetooth
                    default:
                        assertionFailure()
                        return .bluetooth
                    }
            }())

            result.append(entry)
        }
        return result
    }

}
}

extension Database.UploadStatsTable {

    struct LastUpload {
        let started: Date
        let success: Date
    }

    struct UploadLogEntry {
        enum EntryType {
            case started
            case succeeded
            case failed
        }
        let date: Date
        let startDate: Date
        let type: EntryType
        let numberOfEvents: Int
        let message: String?
        let dataType: EventType
    }

}
