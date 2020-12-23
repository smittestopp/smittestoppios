import Foundation
import XCTest
@testable import Smittestopp

class DateOfBirthUploaderTests: XCTestCase {
    var localStorage: MockLocalStorageService!
    var apiService: MockApiService!
    var uploader: DateOfBirthUploader!

    override func setUp() {
        super.setUp()

        localStorage = MockLocalStorageService()
        apiService = MockApiService()

        uploader = DateOfBirthUploader(localStorage: localStorage, apiService: apiService)
    }

    func testNotNeededWhenNotDOB() {
        localStorage.dateOfBirth = nil
        localStorage.isDateOfBirthUploaded = false

        uploader.uploadIfNeeded()

        XCTAssertEqual(apiService._mockSendSendYearOfBirthCalls.count, 0)
    }

    func testNotNeededWhenAlreadyUploaded() {
        localStorage.dateOfBirth = YearMonthDay(year: 2000, month: 11, day: 28)
        localStorage.isDateOfBirthUploaded = true

        uploader.uploadIfNeeded()

        XCTAssertEqual(apiService._mockSendSendYearOfBirthCalls.count, 0)
    }

    func testUploadWhenNeeded() {
        localStorage.dateOfBirth = YearMonthDay(year: 1997, month: 11, day: 28)
        localStorage.isDateOfBirthUploaded = false

        uploader.uploadIfNeeded()

        XCTAssertEqual(apiService._mockSendSendYearOfBirthCalls.count, 1)
        XCTAssertEqual(apiService._mockSendSendYearOfBirthCalls[0].year, 1997)
    }
}
