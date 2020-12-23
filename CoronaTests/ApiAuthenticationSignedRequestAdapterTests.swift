import Alamofire
import Foundation
import XCTest
@testable import Smittestopp

class ApiAuthenticationSignedRequestAdapterTests: XCTestCase {
    var mockLocalStorage: MockLocalStorageService!
    var mockDateService: MockDateService!

    override func setUp() {
        super.setUp()
        mockLocalStorage = MockLocalStorageService()
        mockDateService = MockDateService()
    }

    /*
     Generated reference signature with the following script:

     #!/usr/bin/env python3

     import asyncio
     import base64
     import hmac
     import time

     def create_signature(message, key):
         digest = hmac.new(key, message, 'sha256').digest()
         return base64.b64encode(digest).decode("ascii")

     deviceId = '1234567890abcdefghijklmnopqrstuv'
     deviceKey = base64.b64decode('aGVsbG8=')
     timestamp = '974982896'
     verb = "GET"
     path = "/foobar"

     message = f"{deviceId}|{timestamp}|{verb}|{path}".encode("utf8")
     sig = create_signature(message, deviceKey)
     print(f"signature={sig}")
     */
    func testSuccessfulSignedRequest() {
        let adapter = ApiAuthenticationSignedRequestAdapter(
            localStorage: mockLocalStorage, dateService: mockDateService)

        let deviceId = mockLocalStorage.user!.deviceId!
        let time = mockDateService.now

        let request = URLRequest(url: URL(string: "https://example.com/ignoreme/foobar")!)

        adapter.adapt(request, for: Session()) { result in
            switch result {
            case let .failure(error):
                XCTFail(error.localizedDescription)
            case let .success(adaptedRequest):
                XCTAssertEqual(
                    adaptedRequest.headers.value(for: "Authorization"),
                    "SMST-HMAC-SHA256 \(deviceId);\(time.unixTime);6owDVwdBh+ud0qybfunQhSWd46mfK7ElClIxrgz2tQw=")
            }
        }
    }

    func testComposingPayloadForSigning() {
        let identity: ((String, String)->String?) = { payload, _ in payload }

        let adapter = ApiAuthenticationSignedRequestAdapter(
            localStorage: mockLocalStorage, dateService: mockDateService,
            sign: identity)

        let deviceId = mockLocalStorage.user!.deviceId!
        let time = mockDateService.now

        let request = URLRequest(url: URL(string: "https://example.com/ignoreme/foobar")!)

        adapter.adapt(request, for: Session()) { result in
            switch result {
            case let .failure(error):
                XCTFail(error.localizedDescription)
            case let .success(adaptedRequest):
                XCTAssertEqual(
                    adaptedRequest.headers.value(for: "Authorization"),
                    "SMST-HMAC-SHA256 \(deviceId);\(time.unixTime);1234567890abcdefghijklmnopqrstuv|974982896|GET|/foobar")
            }
        }
    }
}
