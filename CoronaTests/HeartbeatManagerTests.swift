import XCTest
@testable import Smittestopp

class HeartbeatManagerTests: XCTestCase {
    struct MockDependencyContainer: HeartbeatManager.Dependencies {
        var mockLocalStorage = MockLocalStorageService()
        var mockLocationManager = MockLocationManager()
        var mockDateService = MockDateService()
        var mockIoTHubService = MockIoTHubService()
        var mockDeviceTraits = MockDeviceTraitsService()
        var mockBundle = MockBundleService()
        var mockBleIdentifierService = MockBLEIdentifierService()

        var localStorage: LocalStorageServiceProviding { return mockLocalStorage }
        var locationManager: LocationManagerProviding { return mockLocationManager }
        var dateService: DateServiceProviding { return mockDateService }
        var iotHubService: IoTHubServiceProviding { return mockIoTHubService }
        var deviceTraits: DeviceTraitsServiceProviding { return mockDeviceTraits }
        var bundle: BundleServiceProviding { return mockBundle }
        var bleIdentifierService: BLEIdentifierServiceProviding { mockBleIdentifierService }
    }

    let oneMinute: TimeInterval = 1 * 60

    func testNextHeartbeatDate() {
        let deps = MockDependencyContainer()
        let interval: TimeInterval = 123456
        let heartbeat = HeartbeatManager(dependencies: deps, minimumInterval: interval)

        deps.mockLocalStorage.lastHeartbeat = nil

        XCTAssertEqual(heartbeat.nextHeartbeatDate, deps.dateService.now)

        let lastHeartbeat = deps.dateService.now.addingTimeInterval(-543)
        let nextHeartbeat = lastHeartbeat.addingTimeInterval(interval)

        deps.mockLocalStorage.lastHeartbeat = lastHeartbeat
        XCTAssertEqual(heartbeat.nextHeartbeatDate, nextHeartbeat)
    }

    func testNextHeartbeatDate_inThePast() {
        let deps = MockDependencyContainer()
        let interval: TimeInterval = 123456
        let heartbeat = HeartbeatManager(dependencies: deps, minimumInterval: interval)

        let lastHeartbeat = deps.dateService.now.addingTimeInterval(-interval * 2)

        deps.mockLocalStorage.lastHeartbeat = lastHeartbeat
        XCTAssertEqual(heartbeat.nextHeartbeatDate, deps.dateService.now)
    }

    func testShouldSend() {
        let deps = MockDependencyContainer()
        let heartbeat = HeartbeatManager(dependencies: deps, minimumInterval: oneMinute)

        deps.mockLocalStorage.lastHeartbeat = nil
        XCTAssertTrue(heartbeat.shouldSendHeartbeat)

        let thirtySeconds: TimeInterval = 1 * 30
        let twoMinutes: TimeInterval = 2 * 60

        deps.mockLocalStorage.lastHeartbeat = deps.dateService.now.addingTimeInterval(-thirtySeconds)
        XCTAssertFalse(heartbeat.shouldSendHeartbeat)

        deps.mockLocalStorage.lastHeartbeat = deps.dateService.now.addingTimeInterval(-twoMinutes)
        XCTAssertTrue(heartbeat.shouldSendHeartbeat)
    }

    func testSendIfNeeded() {
        let deps = MockDependencyContainer()
        let heartbeat = HeartbeatManager(dependencies: deps, minimumInterval: oneMinute)

        let thirtySeconds: TimeInterval = 1 * 30

        deps.mockLocalStorage.lastHeartbeat = deps.dateService.now.addingTimeInterval(-thirtySeconds)
        XCTAssertFalse(heartbeat.shouldSendHeartbeat)

        var result: Result<Void, HeartbeatManager.Error>?
        // it should NOT send
        heartbeat.sendIfNeeded { res in
            result = res
        }
        XCTAssertEqual(deps.mockIoTHubService._mockSendCalls.count, 0)
        XCTAssertNotNil(result)
        switch result! {
        case .failure(.notNeeded):
            break
        case .failure:
            XCTFail()
        case .success:
            XCTFail()
        }
        XCTAssertEqual(deps.mockIoTHubService._mockSendCalls.count, 0)
    }

    func testSendIfNeededMultipleCalls() {
        let deps = MockDependencyContainer()
        let heartbeat = HeartbeatManager(dependencies: deps, minimumInterval: oneMinute)

        let twentyFiveHours: TimeInterval = 25 * 60 * 60

        deps.mockLocalStorage.lastHeartbeat = deps.dateService.now.addingTimeInterval(-twentyFiveHours)
        XCTAssertTrue(heartbeat.shouldSendHeartbeat)

        deps.mockIoTHubService._mockSendCompletion = { completion in
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                completion(.success(()))
            }
        }

        var completionCallCountNotNeeded = 0
        var completionCallCountSuccess = 0
        let completion: ((Result<Void, HeartbeatManager.Error>)->Void) = { result in
            switch result {
            case .failure(.notNeeded):
                completionCallCountNotNeeded += 1
            case let .failure(error):
                XCTFail("Unexpected error: \(error)")
            case .success:
                completionCallCountSuccess += 1
            }
        }

        // we call sendIfNeeded multiple times but send itself takes 1 second to complete
        // It should actually only send once
        heartbeat.sendIfNeeded(completion)
        heartbeat.sendIfNeeded(completion)
        heartbeat.sendIfNeeded(completion)
        heartbeat.sendIfNeeded(completion)
        heartbeat.sendIfNeeded(completion)
        heartbeat.sendIfNeeded(completion)
        heartbeat.sendIfNeeded(completion)
        heartbeat.sendIfNeeded(completion)

        wait(timeout: 2) { expectation in
            XCTAssertEqual(deps.mockIoTHubService._mockSendCalls.count, 1)
            XCTAssertEqual(completionCallCountNotNeeded, 7)
            XCTAssertEqual(completionCallCountSuccess, 1)
            expectation.fulfill()
        }
    }

    func testSendWithBluetoothDisabled() {
        let deps = MockDependencyContainer()
        let heartbeat = HeartbeatManager(dependencies: deps, minimumInterval: oneMinute)

        let fakeDate = Date.makeGMT(year: 2000, month: 11, day: 23,
                                    hour: 12, minute: 34, second: 56)

        deps.mockLocationManager.gpsState = .init(authorizationStatus: .enabledAlways, isLocationServiceEnabled: true)
        deps.mockLocationManager.bluetoothState = .init(authorization: .denied, power: .off)
        deps.mockLocalStorage.isTrackingEnabled = true
        deps.mockLocalStorage.lastHeartbeat = nil
        deps.mockDateService.now = fakeDate

        var result: Result<Void, HeartbeatManager.Error>?
        heartbeat.send { res in
            result = res
        }

        XCTAssertNotNil(result)
        XCTAssertNoThrow(try result!.get())

        XCTAssertEqual(deps.mockIoTHubService._mockSendCalls.count, 1)
        let call = deps.mockIoTHubService._mockSendCalls[0]
        XCTAssertEqual(call.messageType, "sync")

        XCTAssertEqual(call.data.appVersion, "99.88.77-mock")
        XCTAssertEqual(call.data.osVersion, "444.222")
        XCTAssertEqual(call.data.model, "MockPhone1,1")
        XCTAssertEqual(call.data.jailbroken, false)

        switch call.data.events {
        case let .sync(event):
            XCTAssertEqual(event.timestamp.description, "2000-11-23 12:34:56 +0000")
            XCTAssertEqual(event.status.rawValue, 1)
        case .gps:
            XCTFail()
        case .bluetooth:
            XCTFail()
        }

        // ensure it stored the heartbeat date
        XCTAssertEqual(deps.localStorage.lastHeartbeat, fakeDate)
    }

    func testSendAllEnabled() {
        let deps = MockDependencyContainer()
        let heartbeat = HeartbeatManager(dependencies: deps, minimumInterval: oneMinute)

        let fakeDate = Date.makeGMT(year: 2000, month: 11, day: 23,
                                    hour: 12, minute: 34, second: 56)

        deps.mockLocationManager.gpsState = .init(authorizationStatus: .enabledAlways, isLocationServiceEnabled: true)
        deps.mockLocationManager.bluetoothState = .init(authorization: .allowedAlways, power: .on)
        deps.mockLocalStorage.isTrackingEnabled = true
        deps.mockLocalStorage.lastHeartbeat = nil
        deps.mockDateService.now = fakeDate

        var result: Result<Void, HeartbeatManager.Error>?
        heartbeat.send { res in
            result = res
        }

        XCTAssertNotNil(result)
        XCTAssertNoThrow(try result!.get())

        XCTAssertEqual(deps.mockIoTHubService._mockSendCalls.count, 1)
        let call = deps.mockIoTHubService._mockSendCalls[0]
        XCTAssertEqual(call.messageType, "sync")

        switch call.data.events {
        case let .sync(event):
            XCTAssertEqual(event.timestamp.description, "2000-11-23 12:34:56 +0000")
            XCTAssertEqual(event.status.rawValue, 0)
        case .gps:
            XCTFail()
        case .bluetooth:
            XCTFail()
        }

        // ensure it stored the heartbeat date
        XCTAssertEqual(deps.localStorage.lastHeartbeat, fakeDate)
    }
}
