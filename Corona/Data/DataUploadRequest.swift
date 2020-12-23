import Foundation

struct DataUploadRequest: Encodable {
    let appVersion: String
    let model: String
    let events: EventData
    let platform: String
    let osVersion: String
    let jailbroken: Bool
}
