import UIKit
@testable import Smittestopp

class MockLoginService: LoginServiceProviding {
    func signIn(on _: UIViewController, _ completion: @escaping ((Result<LoginService.Token, LoginService.Error>) -> Void)) {
        completion(.success(.init(accessToken: "hello", expiresOn: Date().advanced(by: 3600), phoneNumber: "+47 123 456 789")))
    }

    func attemptDeviceRegistration() {
    }

    func registerDevice(_: LoginService.Token, _ completion: @escaping ((Result<Void, LoginService.Error>) -> Void)) {
        completion(.success(()))
    }
}
