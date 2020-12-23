import Alamofire
import Foundation

fileprivate extension String {
    static let api = "API"
}

protocol ApiServiceProviding: class {
    /// Register current device and return IoT Hub connection info.
    func registerDevice(accessToken: String, _ completion: @escaping ((Result<ApiService.RegisterDeviceResponse, ApiService.APIError>)->Void))
    /// Trigger request to delete all data associated with this user on the backend.
    func sendDataDeletionRequest(accessToken: String, _ completion: @escaping ((Result<Void, ApiService.APIError>)->Void))
    /// Upload year of birth to the backend to register age of the user.
    func sendYearOfBirth(year: Int, _ completion: @escaping ((Result<Void, ApiService.APIError>)->Void))
    /// Fetch PIN codes
    func getPinCodes(_ completion: @escaping ((Result<ApiService.PinCodeResponse, ApiService.APIError>)->Void))
    /// Get bluetooth identifiers
    func getDeviceIds(_ completion: @escaping (Result<[String], ApiService.APIError>) -> Void)
}

protocol HasApiService {
    var apiService: ApiServiceProviding { get }
}

class ApiService: ApiServiceProviding {
    enum APIError: Swift.Error {
        case afError(AFError)
        case unknown(String)
        case dataEmpty
        case dataCorrupt

        var localizedDescription: String {
            switch self {
            case let .afError(error):
                return "network error: \(error)"
            case let .unknown(message):
                return "unknown: \(message)"
            case .dataEmpty:
                return "No data to send."
            case .dataCorrupt:
                return "Data was corrupt."
            }
        }
    }

    let authAdapterWithSignedRequest: ApiAuthenticationSignedRequestAdapter
    lazy var interceptorWithSignedRequest: Interceptor = {
        return Interceptor(adapters: [authAdapterWithSignedRequest], retriers: [])
    }()

    let session: Session

    let jsonEncoder: JSONEncoder = .standard
    let jsonDecoder: JSONDecoder = .standard

    private let baseUrl: String

    init(baseUrl: String,
         localStorage: LocalStorageServiceProviding,
         dateService: DateServiceProviding,
         session: Session = .default) {
        self.baseUrl = baseUrl
        self.session = session

        authAdapterWithSignedRequest = ApiAuthenticationSignedRequestAdapter(
            localStorage: localStorage,
            dateService: dateService)
    }

    struct RegisterDeviceResponse: Decodable {
        let DeviceId: String
        let HostName: String
        let SharedAccessKey: String
        let ConnectionString: String
    }

    struct PinCodeResponse: Decodable {
        let pinCodes: [PinCode]

        struct PinCode: Decodable {
            let pinCode: String
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case pinCode = "pin_code"
                case createdAt = "created_at"
            }
        }

        enum CodingKeys: String, CodingKey {
            case pinCodes = "pin_codes"
        }
    }

    struct ContactIdsResponse: Decodable {
        let contactIds: [String]

        enum CodingKeys: String, CodingKey {
            case contactIds = "contact_ids"
        }
    }

    func registerDevice(accessToken: String, _ completion: @escaping ((Result<RegisterDeviceResponse, APIError>)->Void)) {
        let interceptor = Interceptor(
            adapters: [ApiAuthenticationAccessTokenAdapter(accessToken)],
            retriers: [])

        request(.DeviceRegistration, method: .post, interceptor: interceptor)
            .responseData { response in
                switch response.result {
                case let .failure(error):
                    completion(.failure(.unknown(error.localizedDescription)))
                case let .success(data):
                    do {
                        let model = try self.jsonDecoder.decode(RegisterDeviceResponse.self, from: data)
                        completion(.success(model))
                    } catch {
                        Logger.error("RegisterDevice: Failed to parse response: \(error)", tag: .api)
                        let json = String(data: data, encoding: .utf8) ?? "nil"
                        Logger.debug("RegisterDevice: Raw response: \(json)", tag: .api)
                        completion(.failure(.dataCorrupt))
                    }
                }
        }
    }

    func sendDataDeletionRequest(accessToken: String, _ completion: @escaping ((Result<Void, APIError>)->Void)) {
        let interceptor = Interceptor(
            adapters: [ApiAuthenticationAccessTokenAdapter(accessToken)],
            retriers: [])

        request(.DataDeletion, method: .post, interceptor: interceptor)
            .response { response in
                switch response.result {
                case let .failure(error):
                    completion(.failure(.unknown(error.localizedDescription)))
                case .success:
                    completion(.success(()))
                }
        }
    }

    private func request(
        _ endpoint: ApiEndpoint, method: HTTPMethod,
        interceptor: Interceptor) -> DataRequest {
        return session.request(
            endpoint.url(baseUrl: baseUrl),
            method: method,
            interceptor: interceptor)
    }

    private func request<Payload: Encodable>(
        _ endpoint: ApiEndpoint, method: HTTPMethod,
        body: Payload?, interceptor: Interceptor) -> DataRequest {
        return session.request(
            endpoint.url(baseUrl: baseUrl),
            method: method,
            parameters: body,
            encoder: JSONParameterEncoder(encoder: jsonEncoder),
            interceptor: interceptor)
    }

    func sendYearOfBirth(year: Int, _ completion: @escaping ((Result<Void, APIError>)->Void)) {
        struct Payload: Encodable {
            let birthyear: Int
        }
        let payload = Payload(birthyear: year)

        request(.YearOfBirth, method: .post, body: payload, interceptor: interceptorWithSignedRequest)
            .validate()
            .response { response in
                switch response.result {
                case let .failure(error):
                    completion(.failure(.unknown(error.localizedDescription)))
                case .success:
                    completion(.success(()))
                }
        }
    }

    func getPinCodes(_ completion: @escaping ((Result<PinCodeResponse, APIError>)->Void)) {
        request(.PinCodes, method: .get, interceptor: interceptorWithSignedRequest)
            .validate()
            .responseDecodable(of: PinCodeResponse.self, decoder: jsonDecoder, completionHandler: { response in
                switch response.result {
                case let .failure(error):
                    completion(.failure(.unknown(error.localizedDescription)))
                case let .success(payload):
                    completion(.success(payload))
                }
        })
    }

    func getDeviceIds(_ completion: @escaping (Result<[String], APIError>) -> Void) {
        request(.contactIds, method: .post, interceptor: interceptorWithSignedRequest)
        .validate()
            .responseDecodable(of: ContactIdsResponse.self) { response in
                switch response.result {
                case let .success(payload):
                    completion(.success(payload.contactIds))
                case let .failure(error):
                    completion(.failure(.afError(error)))
                }
        }
    }
}
