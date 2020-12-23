import CoreLocation
import XCTest
@testable import Smittestopp

class CoronaTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGPSDistance() {
        // The user is at location d1 from t1 to t2 and at location d3 from t3
        let t1 = Utils.shared.dateFromString(str: "2020-01-01T00:00:00Z")!
        let t2 = Utils.shared.dateFromString(str: "2020-01-01T00:01:00Z")!
        let t3 = Utils.shared.dateFromString(str: "2020-01-01T00:02:00Z")!
        let t4 = Utils.shared.dateFromString(str: "2020-01-01T00:04:00Z")!
        let t5 = Utils.shared.dateFromString(str: "2020-01-01T00:05:00Z")!

        let d1 = GPSData(from: t1, to: t2, lat: 59.901561, lon: 10.624793, accuracy: 6, speed: 0, altitude: 0, altitudeAccuracy: 0)
        let d2 = GPSData(from: t2, to: t3, lat: 59.901459, lon: 10.624857, accuracy: 6, speed: 0, altitude: 0, altitudeAccuracy: 0)
        let d3 = GPSData(from: t3, to: t4, lat: 59.900781, lon: 10.625211, accuracy: 6, speed: 0, altitude: 0, altitudeAccuracy: 0)
        // Note: t4 - t3 is 2 minutes which is more than PAUSE_GPS_IDLE_PERIOD so that d3 and d4 can not be merged even though
        //       it's the same location
        let d4 = GPSData(from: t4, to: t5, lat: 59.900781, lon: 10.625211, accuracy: 6, speed: 0, altitude: 0, altitudeAccuracy: 0)
        let d5 = GPSData(from: t5, to: t5, lat: 59.900781, lon: 10.625211, accuracy: 6, speed: 0, altitude: 0, altitudeAccuracy: 0)

        // Shoud return just one EventData virtually equal to d1
        let e1 = gpsDataToEventDatas(gpsData: [d1])
        XCTAssert(e1.count == 1)
        XCTAssert(e1[0].timeFrom == d1.from && e1[0].timeTo == d1.to && e1[0].latitude == d1.lat && e1[0].longitude == d1.lon)

        // The distance between these two points should be around 11.89 meters
        let distanceD1D2 = e1[0].location.distance(from: d2.location)
        XCTAssert(distanceD1D2 > 11.7 && distanceD1D2 < 12)

        // The distance between these two points should be around 89.81 meters
        let distanceD1D3 = e1[0].location.distance(from: d3.location)
        XCTAssertEqual(distanceD1D3, 90, accuracy: 1)

        // d1 and d3 are too far away, so none of them should be cleaned up
        let e2 = gpsDataToEventDatas(gpsData: [d1, d3])
        XCTAssert(e2.count == 2)
        XCTAssert(e2.elementsEqual([d1, d3]) {
            $0.latitude == $1.lat && $0.longitude == $1.lon
        })

        // d1 and d2 are close (<12m), so d2 should be merged with d1 and only d1 and d3 should be returned
        let e3 = gpsDataToEventDatas(gpsData: [d1, d2, d3])
        XCTAssertEqual(e3.count, 3)
        // Lat and lon check
        XCTAssert(e3.elementsEqual([d1, d2, d3]) {
            $0.latitude == $1.lat && $0.longitude == $1.lon
        })
        // Check that user is considered to have been at d1 from t1 to t2
        XCTAssertEqual(e3[0].timeFrom, d1.from)
        XCTAssertEqual(e3[0].timeTo, d1.to)

        let e4 = gpsDataToEventDatas(gpsData: [d1, d2, d3, d4, d5])
        XCTAssert(e4.count == 5)
        XCTAssert(e4.elementsEqual([d1, d2, d3, d4, d5]) {
            $0.latitude == $1.lat && $0.longitude == $1.lon
        })
    }
}
