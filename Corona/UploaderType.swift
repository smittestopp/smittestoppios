import Foundation

protocol UploaderType {
    func uploadTrigger()
    func uploadGPSTrigger()
    func uploadBLETrigger()
    func upload(_ eventType: EventType)
}
