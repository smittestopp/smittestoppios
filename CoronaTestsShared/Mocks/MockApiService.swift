import Foundation
@testable import Smittestopp

class MockApiService: ApiServiceProviding {
    var deviceIdsToReturn: [String]?
    var getDeviceIdsCallCount = 0
    func getDeviceIds(_ completion: @escaping (Result<[String], ApiService.APIError>) -> Void) {
        getDeviceIdsCallCount += 1

        if let deviceIdsToReturn = deviceIdsToReturn {
            completion(.success(deviceIdsToReturn))
            return
        }

        func randomString(length: Int) -> String {
          let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
          return String((0..<length).map{ _ in letters.randomElement()! })
        }

        let randomIds = (0...100).map { _ in randomString(length: 10) }
        completion(.success(randomIds))
    }

    var registerDeviceCalls = 0
    func registerDevice(accessToken _: String, _: @escaping ((Result<ApiService.RegisterDeviceResponse, ApiService.APIError>)->Void)) {
        registerDeviceCalls += 1
    }
    func sendDataDeletionRequest(accessToken _: String, _: @escaping ((Result<Void, ApiService.APIError>)->Void)) { }
    func post(withData _: DataUploadRequest, messageType _: String, _: @escaping ((Result<Void, ApiService.APIError>)->Void)) { }
    func sendYearOfBirth(year: Int, _ completion: @escaping ((Result<Void, ApiService.APIError>) -> Void)) {
        _mockSendSendYearOfBirthCalls.append(.init(year: year))

        _mockSendYearOfBirthCompletion { result in
            completion(result)
        }
    }
    func getPinCodes(_: @escaping ((Result<ApiService.PinCodeResponse, ApiService.APIError>) -> Void)) {
    }

    // MARK: Mock-specific

    struct SendYearOfBirthArgs {
        let year: Int
    }
    typealias SendYearOfBirthCompletion = ((Result<Void, ApiService.APIError>)->Void)
    var _mockSendYearOfBirthCompletion: ((@escaping SendYearOfBirthCompletion)->Void) = { completion in completion(.success(())) }
    var _mockSendSendYearOfBirthCalls: [SendYearOfBirthArgs] = []
}
