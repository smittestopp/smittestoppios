import Foundation

struct SMSCodeRequest: Codable {
    let number: String
    let code: String
}
