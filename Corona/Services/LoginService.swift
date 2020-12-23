import Foundation
import JWTDecode
import MSAL

fileprivate extension String {
    static let login = "LoginService"
}

protocol LoginServiceProviding {
    func signIn(on viewController: UIViewController, _ completion: @escaping ((Result<LoginService.Token, LoginService.Error>)->Void))
    func attemptDeviceRegistration()
    func registerDevice(_ token: LoginService.Token, _ completion: @escaping ((Result<Void, LoginService.Error>)->Void))
}

protocol HasLoginService {
    var loginService: LoginServiceProviding { get }
}

class LoginService: LoginServiceProviding {
    struct Token {
        let accessToken: String
        let expiresOn: Date
        let phoneNumber: String?
    }

    private let config = AppConfiguration.shared.azureIdentityConfig

    // How long before real token expiration time do we consider it expired?
    static let SECONDS_EARLIER_TOKEN_EXPIRES: TimeInterval = 60 * 60 * 2 // Two hours should be enough.

    enum Error: Swift.Error {
        case userCancelled
        case application(Swift.Error)
        case badAuthority(url: String, error: Swift.Error?)
        case acquireToken(Swift.Error)
        case badJwt(Swift.Error)
        case deviceRegistrationError(ApiService.APIError)
    }

    private let localStorage: LocalStorageServiceProviding
    private let apiService: ApiServiceProviding

    init(localStorage: LocalStorageServiceProviding,
         apiService: ApiServiceProviding) {
        self.localStorage = localStorage
        self.apiService = apiService
    }

    /// Acquire a token for a new account using interactive authentication
    func signIn(on viewController: UIViewController, _ completion: @escaping ((Result<Token, LoginService.Error>)->Void)) {
        let application: MSALPublicClientApplication
        do {
            application = try createApplication(
                clientId: config.kClientID,
                policy: config.kSignupOrSigninPolicy,
                tenantName: config.kTenantName,
                authorityHostName: config.kAuthorityHostName)

            // authority is a URL indicating a directory that MSAL can use to obtain tokens. In Azure B2C
            // it is of the form `https://<instance/tfp/<tenant>/<policy>`, where `<instance>` is the
            // directory host (e.g. https://login.microsoftonline.com), `<tenant>` is a
            // identifier within the directory itself (e.g. a domain associated to the
            // tenant, such as contoso.onmicrosoft.com), and `<policy>` is the policy you wish to
            // use for the current user flow.

            let authority = try getAuthority(
                forPolicy: config.kSignupOrSigninPolicy,
                tenantName: config.kTenantName,
                authorityHostName: config.kAuthorityHostName)

            let webViewParameters = MSALWebviewParameters(parentViewController: viewController)
            let parameters = MSALInteractiveTokenParameters(scopes: config.kScopes, webviewParameters: webViewParameters)
            parameters.promptType = .selectAccount
            parameters.authority = authority
            application.acquireToken(with: parameters) { result, error in
                if let error = error {
                    if (error as NSError).domain == MSALErrorDomain {
                        let msalError = error as NSError
                        switch msalError.code {
                        case MSALError.userCanceled.rawValue:
                            completion(.failure(.userCancelled))
                            return
                        default:
                            break
                        }
                    }
                    Logger.error("Could not acquire token: \(error)", tag: .login)
                    completion(.failure(Error.acquireToken(error)))
                    return
                }

                guard let result = result else {
                    Logger.error("Unexpected condition, no error and not result while acquiring a token", tag: .login)
                    assertionFailure()
                    return
                }

                Logger.debug("Access token is \(result.accessToken)", tag: .login)

                let phoneNumber: String?
                do {
                    let jwt = try decode(jwt: result.accessToken)
                    phoneNumber = jwt.claim(name: "signInNames.phoneNumber").string
                } catch {
                    completion(.failure(.badJwt(error)))
                    return
                }

                let value = Token(
                    accessToken: result.accessToken,
                    expiresOn: result.expiresOn,
                    phoneNumber: phoneNumber)

                completion(.success(value))
            }
        } catch let error as Error {
            completion(.failure(error))
            return
        } catch {
            // TODO:
            return
        }
    }

    /// Initialize a MSALPublicClientApplication with a MSALPublicClientApplicationConfig.
    /// MSALPublicClientApplicationConfig can be initialized with client id, redirect uri and authority.
    /// Redirect uri will be constucted automatically in the form of "msal<your-client-id-here>://auth" if not provided.
    /// The scheme part, i.e. "msal<your-client-id-here>", needs to be registered in the info.plist of the project
    private func createApplication(
        clientId: String, policy: String,
        tenantName: String, authorityHostName: String) throws -> MSALPublicClientApplication {
        let siginPolicyAuthority = try getAuthority(
            forPolicy: policy, tenantName: tenantName, authorityHostName: authorityHostName)

        // Provide configuration for MSALPublicClientApplication
        // MSAL will use default redirect uri when you provide nil
        let pcaConfig = MSALPublicClientApplicationConfig(
            clientId: clientId, redirectUri: nil, authority: siginPolicyAuthority)
        pcaConfig.knownAuthorities = [siginPolicyAuthority]
        do {
            return try MSALPublicClientApplication(configuration: pcaConfig)
        } catch {
            throw Error.application(error)
        }
    }

    /// The way B2C knows what actions to perform for the user of the app is through the use of `Authority URL`.
    /// It is of the form `https://<instance/tfp/<tenant>/<policy>`, where `<instance>` is the
    /// directory host (e.g. https://login.microsoftonline.com), `<tenant>` is a
    /// identifier within the directory itself (e.g. a domain associated to the
    /// tenant, such as contoso.onmicrosoft.com), and `<policy>` is the policy you wish to
    /// use for the current user flow.
    private func getAuthority(
        forPolicy policy: String, tenantName: String,
        authorityHostName: String) throws -> MSALB2CAuthority {
        // DO NOT CHANGE - This is the format of OIDC Token and Authorization endpoints for Azure AD B2C.
        let kEndpoint = "https://%@/tfp/%@/%@"

        let urlString = String(format: kEndpoint, authorityHostName, tenantName, policy)

        guard let authorityURL = URL(string: urlString) else {
            throw Error.badAuthority(url: urlString, error: nil)
        }

        do {
            return try MSALB2CAuthority(url: authorityURL)
        } catch {
            throw Error.badAuthority(url: urlString, error: error)
        }
    }

    public func attemptDeviceRegistration() {
        guard let user = localStorage.user else {
            return
        }

        assert(user.connectionString == nil)
        guard user.connectionString == nil else {
            return
        }

        guard user.expiresOn.timeIntervalSinceNow - LoginService.SECONDS_EARLIER_TOKEN_EXPIRES > 0 else {
            NotificationCenter.default.post(name: NotificationType.TokenExpired, object: self)
            return
        }

        let nextAttempt = localStorage.nextProvisioningAttempt ?? Date()
        guard nextAttempt.timeIntervalSinceNow <= 0 else {
            return
        }

        Logger.info("Attempting device provisioning.", tag: .login)

        // Set next attempt time with +/- 30 minutes jitter.
        let jitter = Double.random(in: -30...30) * 60
        let waitTime = 60.0 * 60.0
        localStorage.nextProvisioningAttempt = Date(timeIntervalSinceNow: waitTime + jitter)
        let token = LoginService.Token(accessToken: user.accessToken,
                                       expiresOn: user.expiresOn,
                                       phoneNumber: user.phoneNumber)
        registerDevice(token, { _ in
            // Nothing todo here for now.
        })
    }

    public func registerDevice(_ token: LoginService.Token, _ completion: @escaping ((Result<Void, LoginService.Error>)->Void)) {
        apiService.registerDevice(accessToken: token.accessToken) { result in
            switch result {
            case let .success(response):
                let user = LocalStorageService.User(
                    accessToken: token.accessToken, expiresOn: token.expiresOn, phoneNumber: token.phoneNumber,
                    deviceId: response.DeviceId,
                    connectionString: response.ConnectionString)

                self.localStorage.user = user

                NotificationCenter.default.post(name: NotificationType.DeviceProvisioned, object: self)

                completion(.success(()))

            case let .failure(error):
                Logger.error("Failed register device: \(error)", tag: "iot")
                completion(.failure(.deviceRegistrationError(error)))
            }
        }
    }
}
