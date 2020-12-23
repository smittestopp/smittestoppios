import Foundation
@testable import Smittestopp

class MockURLProtocol: URLProtocol {

    enum ResponseType {
        case error(Error)
        case success(HTTPURLResponse)
    }

    static var responseType: ResponseType!
    private(set) var activeTask: URLSessionTask?

    private lazy var session: URLSession = {
        let configuration: URLSessionConfiguration = URLSessionConfiguration.ephemeral
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override class func requestIsCacheEquivalent(_: URLRequest, to _: URLRequest) -> Bool {
        false
    }

    override func startLoading() {
        guard let data = MockPinCodeResponse.find(request) else {
            activeTask?.cancel()
            return
        }
        activeTask = session.dataTask(with: request.urlRequest!)
        client?.urlProtocol(self, didLoad: data)
        activeTask?.cancel()
    }

    override func stopLoading() {
        activeTask?.cancel()
    }
}

extension MockURLProtocol: URLSessionDataDelegate {
    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
    }

    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
        switch MockURLProtocol.responseType {
        case .error(let error)?:
            client?.urlProtocol(self, didFailWithError: error)
        case .success(let response)?:
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        default:
            break
        }

        client?.urlProtocolDidFinishLoading(self)
    }
}

extension MockURLProtocol {

    enum MockError: Error {
        case none
    }

    static func responseWithFailure() {
        MockURLProtocol.responseType = MockURLProtocol.ResponseType.error(MockError.none)
    }

    static func responseWithData() {
        MockURLProtocol.responseType = MockURLProtocol.ResponseType.success(HTTPURLResponse(url: URL(string: "https://testing.test")!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}
