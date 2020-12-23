import Foundation
@testable import Smittestopp

class MockIoTHubService: IoTHubServiceProviding {
    var isStarted: Bool = true

    var canStart: Bool = true

    var latestVersion: String?

    func start() {
    }

    func stop() {
    }

    func send(_ data: DataUploadRequest, messageType: String, _ completion: ((Result<Void, IoTHubApi.Error>) -> Void)?) {
        _mockSendCalls.append(.init(data: data, messageType: messageType))

        _mockSendCompletion { result in
            completion?(result)
        }
    }

    // MARK: Mock-specific

    struct SendValue {
        let data: DataUploadRequest
        let messageType: String
    }
    typealias SendCompletion = ((Result<Void, IoTHubApi.Error>)->Void)
    var _mockSendCompletion: ((@escaping SendCompletion)->Void) = { completion in completion(.success(())) }
    var _mockSendCalls: [SendValue] = []
}
