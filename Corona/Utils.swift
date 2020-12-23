import Foundation

class Utils: NSObject {
    let dateFormatter = ISO8601DateFormatter()

    static var shared = Utils()
    override init() {
        super.init()
    }

    func currentDateTime() -> Date {
        return Date()
    }

    func currentDateTimeString() -> String {
        return dateFormatter.string(from: Date())
    }

    func formatDate(date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    func dateFromString(str: String) -> Date? {
        return dateFormatter.date(from: str)
    }
}

func generateRandomString() -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?"
    return String((0..<50).map{ _ in letters.randomElement()! })
}

func gpsDataToEventDatas(gpsData: [GPSData]) -> [GPSEventData] {
    var eventData = [GPSEventData]()

    if gpsData.count == 0 {
        return eventData
    }

    for gd in gpsData {
        // Note: Currently, we just translate GPSData to GPSEventData, so we could also remove
        //       GPSData completely, but I would leave them for now in case we do want to filter/process
        //       in the future.
        eventData.append(GPSEventData(timeFrom: gd.from,
                                      timeTo: gd.to,
                                      latitude: gd.lat,
                                      longitude: gd.lon,
                                      accuracy: gd.accuracy,
                                      speed: gd.speed,
                                      altitude: gd.altitude,
                                      altitudeAccuracy: gd.altitudeAccuracy))
    }

    return eventData
}

func bleDataToEventData(_ value: BLEDetectionData) -> BLEEventData {
    let lastKnownLocation: BLEEventData.Location? = {
        guard let loc = value.lastKnownLocation else {
            return nil
        }
        return .init(latitude: loc.latitude, longitude: loc.longitude,
                     accuracy: loc.accuracy, timestamp: loc.timestamp)
    }()

    return BLEEventData(
        time: value.rssiReading.timestamp,
        deviceId: value.uuid,
        rssi: value.rssiReading.RSSI,
        txPower: value.txPower,
        location: lastKnownLocation)
}

func bleDataToEventDatas(bleData: [BLEDetectionData]) -> [BLEEventData] {
    var eventData = [BLEEventData]()

    if bleData.count == 0 {
        return eventData
    }

    var currentEventData = bleDataToEventData(bleData[0])

    for bd in bleData[1...] {
        if bd.uuid == currentEventData.deviceId,
            bd.rssiReading.RSSI == currentEventData.rssi,
            bd.rssiReading.timestamp.timeIntervalSince(currentEventData.time) <= 1.0 {
            // Considered a duplicate. Skip.
            continue
        } else {
            eventData.append(currentEventData)

            currentEventData = bleDataToEventData(bd)
        }
    }
    eventData.append(currentEventData)

    return eventData
}
