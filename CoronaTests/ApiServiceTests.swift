import Foundation
import XCTest
@testable import Alamofire
@testable import Smittestopp

class ApiServiceTests: XCTestCase {
    private var mockLocalStorage: MockLocalStorageService!
    private var mockDateService: MockDateService!
    private var apiService: ApiService!

    override func setUp() {
        super.setUp()

        let session: Session = {
            let configuration: URLSessionConfiguration = {
                let configuration = URLSessionConfiguration.default
                configuration.protocolClasses = [MockURLProtocol.self]
                return configuration
            }()

            return Session(configuration: configuration)
        }()

        mockLocalStorage = MockLocalStorageService()
        mockDateService = MockDateService()

        apiService = ApiService(
            baseUrl: "https://example.com/",
            localStorage: mockLocalStorage,
            dateService: mockDateService,
            session: session)
    }

    override func tearDown() {
        super.tearDown()

        apiService = nil
    }

    func testResponseWithData() {
        MockURLProtocol.responseWithData()
        let expectation = XCTestExpectation(description: "Request should succeed")

        apiService.getPinCodes { result in
            switch result {
            case let .success(data):
                XCTAssertNotNil(result)
                XCTAssertNotNil(data)

                let pinCodes = data.pinCodes as [ApiService.PinCodeResponse.PinCode]
                XCTAssertEqual(pinCodes.count, 2)
                XCTAssertEqual(pinCodes[0].pinCode, "12345abc")
                XCTAssertEqual(pinCodes[1].pinCode, "zxc123123")

                expectation.fulfill()
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    func testResponseWithFailure() {
        MockURLProtocol.responseWithFailure()
        let expectation = XCTestExpectation(description: "Request should response with failure")

        apiService.getPinCodes { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }
}
