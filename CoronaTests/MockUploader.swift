import Foundation
@testable import Smittestopp

class MockUploader: UploaderType {
    var uploadTriggerCount = 0
    var uploadGPSTriggerCount = 0
    var uploadBLETriggerCount = 0

    func uploadTrigger() {
        uploadTriggerCount += 1
    }

    func uploadGPSTrigger() {
        uploadGPSTriggerCount += 1
    }

    func uploadBLETrigger() {
        uploadBLETriggerCount += 1
    }

    func upload(_: EventType) {
        // no-op
    }
}
