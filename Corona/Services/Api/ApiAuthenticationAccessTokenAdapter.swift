import Alamofire
import Foundation

/// Implements Alamofire-style request adapter for authenticating against backend api by passing a JWT access token.
class ApiAuthenticationAccessTokenAdapter: RequestAdapter {
    let accessToken: String

    init(_ accessToken: String) {
        self.accessToken = accessToken
    }

    func adapt(_ urlRequest: URLRequest, for _: Session, completion: @escaping (Result<URLRequest, Swift.Error>) -> Void) {
        var adaptedRequest = urlRequest
        adaptedRequest.headers.add(.authorization(bearerToken: accessToken))
        completion(.success(adaptedRequest))
    }
}
