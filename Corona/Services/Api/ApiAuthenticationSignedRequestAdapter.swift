import Alamofire
import CryptoSwift
import Foundation

/// Implements Alamofire-style request adapter for authenticating against backend api by signing requests.
///
/// Appends `Authorization` header to the request in the following format:
/// `Authorization: SMST-HMAC-SHA256 deviceId;timestamp;b64digest`
/// where
///   - `deviceId` is the iothub device id
///   - `timestamp` is the unix integer timestamp
///   - `b64digest` is the base64-encoded HMAC SHA256 digest of the message
///     `{device_id}|{timestamp}|{VERB}|{endpoint}`, signed by a device key from iothub:
///     where `VERB` is the HTTP verb in upper case (e.g. GET or POST) and `endpoint` is the name
///     of the endpoint, excluding the first url path component, e.g. /pin for /app/pin
///     or /contentids for /app/contentids.
class ApiAuthenticationSignedRequestAdapter: RequestAdapter {
    enum Error: Swift.Error {
        case noAuth

        var localizedDescription: String {
            switch self {
            case .noAuth:
                return "Missing required authentication parameters"
            }
        }
    }

    /// Generates HMAC-SHA256 of the provided deviceId and timestamp
    /// - Parameters:
    ///   - payload: the message to be signed
    ///   - key: base64-encoded data with the key
    /// - Returns: Returns sig
    static func hmacSHA256(_ payload: String, key: String) -> String? {
        guard let keyBase64 = Data(base64Encoded: key) else {
            return nil
        }

        let value: Array<UInt8> = Array(payload.utf8)

        let result = try! HMAC(key: keyBase64.bytes, variant: .sha256).authenticate(value)
        return Data(result).base64EncodedString()
    }

    typealias SignFunction = ((String, String)->String?)

    let localStorage: LocalStorageServiceProviding
    let dateService: DateServiceProviding
    let sign: SignFunction

    init(localStorage: LocalStorageServiceProviding, dateService: DateServiceProviding,
         sign: @escaping SignFunction = hmacSHA256) {
        self.localStorage = localStorage
        self.dateService = dateService
        self.sign = sign
    }

    func adapt(_ urlRequest: URLRequest, for _: Session, completion: @escaping (Result<URLRequest, Swift.Error>) -> Void) {
        guard
            let deviceId = localStorage.user?.deviceId,
            let connectionString = localStorage.user?.connectionString,
            let deviceKey = IoTHubConnectionInfo(connectionString)?.deviceKey
        else {
            completion(.failure(Error.noAuth))
            return
        }

        let time = dateService.now
        let httpMethod = urlRequest.method?.rawValue.uppercased() ?? "GET"

        guard
            let pathComponents = urlRequest.url?.pathComponents.dropFirst(2),
            !pathComponents.isEmpty
        else {
            completion(.failure(Error.noAuth))
            return
        }

        let httpEndpoint = "/" + pathComponents.joined(separator: "/")

        let payload = [
            deviceId,
            "\(time.unixTime)",
            httpMethod,
            httpEndpoint,
        ].joined(separator: "|")

        guard let signature = sign(payload, deviceKey) else {
            completion(.failure(Error.noAuth))
            return
        }

        let authorization = "SMST-HMAC-SHA256 " + [
            deviceId,
            "\(time.unixTime)",
            signature,
        ].joined(separator: ";")

        var adaptedRequest = urlRequest
        adaptedRequest.headers.add(.authorization(authorization))

        completion(.success(adaptedRequest))
    }
}
