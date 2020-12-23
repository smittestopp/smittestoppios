import Alamofire
import AzureIoTUtility
import Foundation

fileprivate extension String {
    static let iot = "IoTHubApi"
}

extension IoTHubApi {
    enum Error: Swift.Error {
        case notStarted
        case sasTokenCreationFailed
        case messageTooLarge
        case badCredentials
        case afError(AFError)
        case dataCorrupt

        var localizedDescription: String {
            switch self {
            case .notStarted:
                return "notStarted"
            case .sasTokenCreationFailed:
                return "sasTokenCreationFailed"
            case .messageTooLarge:
                return "messageTooLarge"
            case .badCredentials:
                return "badCredentials"
            case .afError(let error):
                return "network error: \(error.localizedDescription)"
            case .dataCorrupt:
                return "dataCorrupt"
            }
        }
    }
}

extension IoTHubApi {
    enum MessageResponse {
        case accepted
        case rejected
        case abandoned

        var httpMethod: String {
            switch self {
            case .accepted:
                return "DELETE"
            case .rejected:
                return "DELETE"
            case .abandoned:
                return "POST"
            }
        }

        func toEndpoint(parameters: EndpointParameters, properties: Properties = Properties(), etag: String) -> Endpoint {
            switch self {
            case .accepted:
                return .AcceptMessage(parameters: parameters, properties: properties, etag: etag)
            case .rejected:
                return .RejectMessage(parameters: parameters, properties: properties, etag: etag)
            case .abandoned:
                return .AbandonMessage(parameters: parameters, properties: properties, etag: etag)
            }
        }
    }
}

extension IoTHubApi {
    struct EndpointParameters {
        let hostName: String
        let deviceId: String
        let apiVersion: String

        let sasToken: String
    }

    enum Endpoint: URLRequestConvertible {
        case SendMessage(parameters: EndpointParameters, properties: Properties = Properties(), message: Data?)
        case ReceiveMessage(parameters: EndpointParameters, properties: Properties = Properties())
        case AcceptMessage(parameters: EndpointParameters, properties: Properties = Properties(), etag: String)
        case RejectMessage(parameters: EndpointParameters, properties: Properties = Properties(), etag: String)
        case AbandonMessage(parameters: EndpointParameters, properties: Properties = Properties(), etag: String)

        func url() -> URL {
            switch self {
                case let .SendMessage(parameters, _, _):
                    return URL(string: "https://\(parameters.hostName)/devices/\(parameters.deviceId)/messages/events?api-version=\(parameters.apiVersion)")!
                case let .ReceiveMessage(parameters, _):
                    return URL(string: "https://\(parameters.hostName)/devices/\(parameters.deviceId)/messages/deviceBound?api-version=\(parameters.apiVersion)")!
                case let .AcceptMessage(parameters, _, etag):
                    return URL(string: "https://\(parameters.hostName)/devices/\(parameters.deviceId)/messages/deviceBound/\(etag)?api-version=\(parameters.apiVersion)")!
                case let .RejectMessage(parameters, _, etag):
                    return URL(string: "https://\(parameters.hostName)/devices/\(parameters.deviceId)/messages/deviceBound/\(etag)?api-version=\(parameters.apiVersion)&reject")!
                case let .AbandonMessage(parameters, _, etag):
                    return URL(string: "https://\(parameters.hostName)/devices/\(parameters.deviceId)/messages/deviceBound/\(etag)/abandon?api-version=\(parameters.apiVersion)")!
            }
        }

        func asURLRequest() throws -> URLRequest {
            var method: String
            var sasToken: String
            var requestProperties: Properties

            var request = URLRequest(url: url())
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            switch self {
            case let .SendMessage(parameters, properties, message):
                method = "POST"
                sasToken = parameters.sasToken
                requestProperties = properties

                request.httpBody = message
            case let .ReceiveMessage(parameters, properties):
                method = "GET"
                sasToken = parameters.sasToken
                requestProperties = properties
            case let .AcceptMessage(parameters, properties, _):
                method = "DELETE"
                sasToken = parameters.sasToken
                requestProperties = properties
            case let .RejectMessage(parameters, properties, _):
                method = "DELETE"
                sasToken = parameters.sasToken
                requestProperties = properties
            case let .AbandonMessage(parameters, properties, _):
                method = "POST"
                sasToken = parameters.sasToken
                requestProperties = properties
            }

            request.httpMethod = method
            request.setValue(sasToken, forHTTPHeaderField: "Authorization")
            request.setProperties(requestProperties)

            return request
        }
    }
}

class IoTHubApi {
    var updatedVersionAvailableCallback: ((String)->Void)?
    var badCredentialsCallback: (() -> Void)?

    struct ClientConfig {
        var deviceId: String!
        var deviceKey: String!
        var hostName: String!
    }

    struct SASToken {
        let token: String
        let expiry: Date
    }

    static let apiVersion = "2016-11-14"
    /// The number of seconds the app will consider the SAS token valid.
    static let SAS_TOKEN_EXPIRY_TIME_SEC: TimeInterval = 60 * 45
    /// Number of extra seconds the SAS token is actually valid.
    static let SAS_TOKEN_EXTRA_EXPIRY_TIME_SEC: TimeInterval = 60 * 15
    /// Maximum allowed size of an IoTHub message in bytes.
    static let MAX_MESSAGE_SIZE_BYTE: Int = 256 * 1024

    private var clientConfig: IoTHubConnectionInfo
    private var sasToken: SASToken?
    private let session = Session()

    init?(_ connectionString: String) {
        guard let config = IoTHubConnectionInfo(connectionString) else {
            Logger.debug("Unable to parse connectionString.", tag: .iot)
            return nil
        }
        clientConfig = config
    }

    func createSasToken() -> SASToken? {
        let earlyExpiry = Date(timeIntervalSinceNow: IoTHubApi.SAS_TOKEN_EXPIRY_TIME_SEC)
        let requestTime = IoTHubApi.SAS_TOKEN_EXTRA_EXPIRY_TIME_SEC
        let actualExpiry = Int(earlyExpiry.timeIntervalSince1970 + requestTime)
        guard let sasHandle = SASToken_CreateString(clientConfig.deviceKey, clientConfig.hostName, "", actualExpiry) else {
            assertionFailure()
            Logger.debug("Could not create SASToken string handle.", tag: .iot)
            return nil
        }
        defer { STRING_delete(sasHandle) }

        guard let sasToken = STRING_c_str(sasHandle) else {
            assertionFailure()
            Logger.debug("Could not read SASToken.", tag: .iot)
            return nil
        }

        return SASToken(token: String(cString: sasToken),
                        expiry: earlyExpiry)
    }

    func getSasToken() -> String? {
        if sasToken == nil || sasToken!.expiry.timeIntervalSinceNow < 0 {
            sasToken = createSasToken()
        }
        return sasToken?.token
    }

    func getEndpointParameters() -> EndpointParameters? {
        guard let sasToken = getSasToken() else {
            assertionFailure()
            return nil
        }

        return EndpointParameters(hostName: clientConfig.hostName,
                                  deviceId: clientConfig.deviceId,
                                  apiVersion: IoTHubApi.apiVersion,
                                  sasToken: sasToken)
    }

    func sendTestMessage() {
        guard let jsonData = "{}".data(using: .utf8) else {
            assertionFailure()
            return
        }
        send(jsonData, messageType: "test") { result in
            switch result {
            case .success:
                Logger.debug("Test message successfully sent", tag: .iot)
            case let .failure(error):
                Logger.debug("Failed to send a test message: \(error)", tag: .iot)
            }
        }
    }

    func send(_ data: Data, messageType: String, _ completion: ((Result<Void, Error>)->Void)? = nil) {
        if data.count >= IoTHubApi.MAX_MESSAGE_SIZE_BYTE {
            Logger.error("Message of \(data.count / 1024) kBytes is too big for IoT", tag: .iot)
            completion?(.failure(.messageTooLarge))
            return
        }

        guard let parameters = getEndpointParameters() else {
            assertionFailure()
            completion?(.failure(.sasTokenCreationFailed))
            return
        }

        let properties = Properties()
        properties.setProperty(key: "eventType", value: messageType)

        session.request(.SendMessage(parameters: parameters, properties: properties, message: data)).validate().responseData { response in
            switch response.result {
            case let .failure(error):
                guard response.response?.statusCode != 404 else {
                    self.badCredentialsCallback?()
                    completion?(.failure(.badCredentials))
                    return
                }
                completion?(.failure(.afError(error)))
            case .success:
                completion?(.success(()))
            }
        }
    }

    func receiveMessage() {
        guard let parameters = getEndpointParameters() else {
            assertionFailure()
            return
        }

        Logger.debug("Fetching IoTHub messages", tag: .iot)
        session.request(.ReceiveMessage(parameters: parameters)).validate().responseData { response in
            switch response.result {
            case let .failure(error):
                guard response.response?.statusCode != 404 else {
                    self.badCredentialsCallback?()
                    return
                }
                Logger.debug("Failed fetching IoTHub messages: \(error.localizedDescription)", tag: .iot)
            case let .success(data):
                guard response.response?.statusCode == 200 else {
                    // 204 response means no messages
                    Logger.debug("Found no IoTHub messages", tag: .iot)
                    return
                }

                guard let headers = response.response?.allHeaderFields as? [String: Any] else {
                    assertionFailure()
                    return
                }

                guard let etag = (headers["Etag"] as? String)?.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) else {
                    assertionFailure()
                    return
                }

                let properties = Properties(fromHeaders: headers)
                let messageResponse = self.receiveMessageCallback(message: data, properties: properties)
                self.respondToMessage(etag, withResponse: messageResponse)
            }
        }
    }

    func respondToMessage(_ etag: String, withResponse response: MessageResponse) {
        guard let parameters = getEndpointParameters() else {
            assertionFailure()
            return
        }

        session.request(response.toEndpoint(parameters: parameters, etag: etag)).responseData { response in
            switch response.result {
            case let .failure(error):
                Logger.error("Failed to respond to received message. \(error.localizedDescription)", tag: .iot)
                assertionFailure()
            case .success:
                Logger.debug("Successfully responded to received message.", tag: .iot)
            }
        }
    }

    /// Check for incoming messages from the cloud
    func runOnce() {
        receiveMessage()
    }

    /// This function is called when a message is received from the IoT hub.
    func receiveMessageCallback(message _: Data, properties: Properties) -> MessageResponse {
        guard let version = properties["iosVersion"] as? String,
        version.split(separator: ".").count == 3 else {
            return .abandoned
        }
        updatedVersionAvailableCallback?(version)
        return .accepted
    }
}

extension IoTHubApi {
    class Properties {

        private static let PROPERTY_PREFIX = "iothub-app-"

        var properties: [String: String?] = [:]
        var systemProperties: [String: String?] = ["iothub-contentencoding": "utf-8",
                                                   "iothub-contenttype": "application/json"]

        init(fromHeaders headers: [String: Any]) {
            for header in headers {
                if header.key.hasPrefix(Properties.PROPERTY_PREFIX) {
                    let propertyName = String(header.key.dropFirst(Properties.PROPERTY_PREFIX.count))
                    properties[propertyName] = header.value as? String
                } else if systemProperties.keys.contains(header.key) {
                    systemProperties[header.key] = header.value as? String
                }
            }
        }

        init() {

        }

        func setProperty(key: String, value: String?) {
            properties["\(Properties.PROPERTY_PREFIX)\(key)"] = value
        }

        func getSystemProperties() -> [String: String?] {
            return systemProperties
        }

        func getProperties() -> [String: String?] {
            return properties
        }

        subscript(key: String) -> String?? {
            return properties[key]
        }
    }
}

fileprivate extension URLRequest {
    mutating func setProperties(_ properties: IoTHubApi.Properties) {
        for systemProperty in properties.getSystemProperties() {
            setValue(systemProperty.value, forHTTPHeaderField: systemProperty.key)
        }

        for userProperty in properties.getProperties() {
            setValue(userProperty.value, forHTTPHeaderField: userProperty.key)
        }
    }
}

fileprivate extension Session {
    func request(_ endpoint: IoTHubApi.Endpoint) -> DataRequest {
        return request(endpoint as URLRequestConvertible)
    }
}
