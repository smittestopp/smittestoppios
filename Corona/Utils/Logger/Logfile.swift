import Foundation

class Logfile {
    static let shared = Logfile()
    var filePath: URL?
    private var fileStream: OutputStream?
    var loggingEnabled: Bool = false {
        didSet {
            if loggingEnabled {
                createStream()
            } else {
                fileStream?.close()
                fileStream = nil
            }
        }
    }

    private init() {
        filePath = try? FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("app_output.log")
        if loggingEnabled {
            createStream()
        }
    }

    deinit {
        if let stream = fileStream {
            stream.close()
        }
    }

    func clearLogFile() {
        fileStream?.close()
        guard let path = filePath else {
            return
        }
        if (try? FileManager.default.removeItem(atPath: path.relativePath)) != nil,
            loggingEnabled {
            createStream()
        }
    }

    func createStream() {
        if let path = filePath {
            fileStream = OutputStream(toFileAtPath: path.relativePath, append: true)
            fileStream?.open()
        } else {
            fileStream = nil
        }
    }

    func write(_ str: String) {
        if loggingEnabled,
            let stream = fileStream {
            let bytes = [UInt8](str.utf8)
            stream.write(bytes, maxLength: bytes.count)
        }
    }
}
