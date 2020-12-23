import Foundation
import XCTest
@testable import Smittestopp

class EventDataTests: XCTestCase {
    static var fakeDate: Date {
        .makeGMT(year: 2000, month: 11, day: 23, hour: 12, minute: 34, second: 56)
    }

    let gpsEvent = GPSEventData(
        timeFrom: fakeDate,
        timeTo: fakeDate,
        latitude: 12, longitude: 34,
        accuracy: 45, speed: 67, altitude: 89, altitudeAccuracy: 90)

    let bleEvent = BLEEventData(
        time: fakeDate,
        deviceId: "abc",
        rssi: 123,
        txPower: nil,
        location: .init(latitude: 12, longitude: 34, accuracy: 56, timestamp: fakeDate))

    let syncEvent = SyncEventData(timestamp: fakeDate, status: .hasLocationOnly)

    func testIsEmpty() {
        XCTAssertEqual(EventData.gps([]).isEmpty, true)
        XCTAssertEqual(EventData.gps([gpsEvent]).isEmpty, false)

        XCTAssertEqual(EventData.bluetooth([]).isEmpty, true)
        XCTAssertEqual(EventData.bluetooth([bleEvent]).isEmpty, false)

        XCTAssertEqual(EventData.sync(syncEvent).isEmpty, false)
    }

    func testEncodingGps() {
        let input = EventData.gps([gpsEvent])
        let data = try! JSONEncoder.standard.encode(input)
        let string = String(data: data, encoding: .utf8)!
        XCTAssertEqual(
            string,
            """
            [{"timeTo":"2000-11-23T12:34:56Z","timeFrom":"2000-11-23T12:34:56Z","speed":67,"longitude":34,"latitude":12,"accuracy":45,"altitude":89,"altitudeAccuracy":90}]
            """)
    }

    func testEncodingBluetooth() {
        let input = EventData.bluetooth([bleEvent])
        let data = try! JSONEncoder.standard.encode(input)
        let string = String(data: data, encoding: .utf8)!
        XCTAssertEqual(
            string,
            """
            [{"deviceId":"abc","rssi":123,"time":"2000-11-23T12:34:56Z","location":{"timestamp":"2000-11-23T12:34:56Z","latitude":12,"accuracy":56,"longitude":34}}]
            """)
    }

    func testEncodingSync() {
        let input = EventData.sync(syncEvent)
        let data = try! JSONEncoder.standard.encode(input)
        let string = String(data: data, encoding: .utf8)!
        XCTAssertEqual(
            string,
            """
            [{"status":1,"timestamp":"2000-11-23T12:34:56Z"}]
            """)
    }
}
