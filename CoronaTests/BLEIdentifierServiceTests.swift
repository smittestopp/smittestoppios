import XCTest
@testable import Smittestopp

class BLEIdentifierServiceTests: XCTestCase {

    var identifierService: BLEIdentifierService!
    var apiService: ApiServiceProviding!
    var localStorage: LocalStorageServiceProviding!

    let defaultExpirationTime: TimeInterval = 15 * 60

    override func setUpWithError() throws {
        apiService = MockApiService()
        localStorage = MockLocalStorageService()
    }

    func testGetsARandomId() throws {
        identifierService = BLEIdentifierService(apiService: apiService,
                                                 localStorage: localStorage,
                                                 expirationTime: defaultExpirationTime,
                                                 refreshTime: 10)
        let id = identifierService.identifierToUse
        XCTAssertNotNil(id)
    }

    func testGetsNewIdAfterExpiration() {
        identifierService = BLEIdentifierService(apiService: apiService,
                                                 localStorage: localStorage,
                                                 expirationTime: 0.5,
                                                 refreshTime: 10)

        // first id
        let id = identifierService.identifierToUse
        XCTAssertNotNil(id)

        // check we still get the same id since it hasn't expired yet
        let id2 = identifierService.identifierToUse
        XCTAssertEqual(id, id2)

        wait(timeout: 0.6) { expectation in
            // grab a new id after expiration time and make sure it's different
            let id3 = self.identifierService.identifierToUse
            XCTAssertNotNil(id3)
            XCTAssertNotEqual(id, id3)

            expectation.fulfill()
        }
    }

    func testUsesExpiredIdAfterAllAreUsed() {
        let mockApiService = MockApiService()
        mockApiService.deviceIdsToReturn = ["123"]

        identifierService = BLEIdentifierService(apiService: mockApiService,
                                                 localStorage: localStorage,
                                                 expirationTime: 0,
                                                 refreshTime: 10)

        // should have fetched more ids
        XCTAssertEqual(mockApiService.getDeviceIdsCallCount, 1)

        let id = identifierService.identifierToUse
        XCTAssertEqual(id?.identifier, "123")

        let id2 = identifierService.identifierToUse

        // enclosing BLEIdentifier should not be equal as it has a new expiration date
        XCTAssertNotEqual(id, id2)

        // identifier string should be equal though
        XCTAssertEqual(id?.identifier, id2?.identifier)
    }

    func testSavesIdsToLocalStorage() {
        XCTAssertEqual(localStorage.bleIdentifiers!.count, 0)
        identifierService = BLEIdentifierService(apiService: apiService,
                                                 localStorage: localStorage,
                                                 expirationTime: defaultExpirationTime,
                                                 refreshTime: 10)
        XCTAssertGreaterThan(localStorage.bleIdentifiers!.count, 10)
    }

    func testGetsNewIds() {
        let mockApiService = MockApiService()
        XCTAssertEqual(mockApiService.getDeviceIdsCallCount, 0)

        identifierService = BLEIdentifierService(apiService: mockApiService,
                                                 localStorage: localStorage,
                                                 expirationTime: defaultExpirationTime,
                                                 refreshTime: 10)
        XCTAssertEqual(mockApiService.getDeviceIdsCallCount, 1)
    }

    func testDoesntGetNewIdsIfAlreadyHaveEnoughInLocalStorage() {
        let mockApiService = MockApiService()
        localStorage.bleIdentifiers = (0...20).map { _ in "bla" }

        identifierService = BLEIdentifierService(apiService: mockApiService,
                                                 localStorage: localStorage,
                                                 expirationTime: defaultExpirationTime,
                                                 refreshTime: 10)
        XCTAssertEqual(mockApiService.getDeviceIdsCallCount, 0)
    }

    func testGetNewIdsIfLocalStorageDoesntHaveEnough() {
        let mockApiService = MockApiService()
        localStorage.bleIdentifiers = (0...2).map { _ in "bla" }

        identifierService = BLEIdentifierService(apiService: mockApiService,
                                                 localStorage: localStorage,
                                                 expirationTime: defaultExpirationTime,
                                                 refreshTime: 10)

        XCTAssertEqual(mockApiService.getDeviceIdsCallCount, 1)
    }

    func testRefreshTimerFetchesNewIds() {
        let mockApiService = MockApiService()
        mockApiService.deviceIdsToReturn = ["123"]

        identifierService = BLEIdentifierService(apiService: mockApiService,
                                                 localStorage: localStorage,
                                                 expirationTime: 0,
                                                 refreshTime: 0.5)

        XCTAssertEqual(mockApiService.getDeviceIdsCallCount, 1)

        wait(timeout: 0.6) { expectation in
            XCTAssertEqual(mockApiService.getDeviceIdsCallCount, 2)
            expectation.fulfill()
        }
    }

    func testUsesExpiredIdsFromLocalStorage() {
        localStorage.bleIdentifiers = ["usableId"]
        localStorage.expiredBleIdentifiers = (0...5).map { _ in "expiredId" }

        let mockApiService = MockApiService()
        mockApiService.deviceIdsToReturn = []

        identifierService = BLEIdentifierService(apiService: mockApiService,
                                                 localStorage: localStorage,
                                                 expirationTime: -1,
                                                 refreshTime: 0.5)

        XCTAssertEqual(identifierService.identifierToUse?.identifier, "usableId")

        XCTAssertEqual(identifierService.identifierToUse?.identifier, "expiredId")
    }

    func testClear() {
        identifierService = BLEIdentifierService(apiService: apiService,
                                                 localStorage: localStorage,
                                                 expirationTime: defaultExpirationTime,
                                                 refreshTime: 10)

        XCTAssertNotNil(identifierService.identifierToUse)

        identifierService.clear()
        XCTAssertNil(identifierService.identifierToUse)
    }
}
