import Foundation

enum ApiEndpoint: String {
    case DeviceRegistration = "/onboarding/register-device"
    case DataDeletion = "/permissions/revoke-consent"
    case YearOfBirth = "/app/birthyear"
    case PinCodes = "/app/pin"
    case contactIds = "app/contactids"

    func url(baseUrl: String) -> URL {
        return URL(string: "\(baseUrl)\(rawValue)")!
    }
}
