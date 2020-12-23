import Alamofire
import Foundation
import XCTest
@testable import Smittestopp

class ApiAuthenticationAccessTokenAdapterTests: XCTestCase {
    func testFoo() {
        let accessToken = "abc132"
        let adapter = ApiAuthenticationAccessTokenAdapter(accessToken)

        let request = URLRequest(url: URL(string: "https://example.com/foobar")!)

        adapter.adapt(request, for: Session()) { result in
            switch result {
            case let .failure(error):
                XCTFail(error.localizedDescription)
            case let .success(adaptedRequest):
                XCTAssertEqual(adaptedRequest.headers.value(for: "Authorization"), "Bearer \(accessToken)")
            }
        }
    }
}
