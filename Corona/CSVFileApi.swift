import Foundation

//
// Note: This can be used to save GPS data into local files on the phone for debugging later.
// To get from the csv files to ploted trajectory:
// 1. get the csv files from the phone
// Xcode => Device and Simulators window => select installed app => the gear button and choose “Download container”
// 2. convert data to KML for Google earth KML
// https://www.gpsvisualizer.com/map?output_data
// 3. import data into Google earth
// https://earth.google.com/web
//

fileprivate extension String {
    static let csv = "CSVFileApi"
}

class CSVFileApi {
    public static let shared = CSVFileApi()

    public var enabled: Bool = false
    private var initialized = false
    private var logEventDataFile: FileHandle?
    private var logRawEventDataFile: FileHandle?

    private func initialize() {
        let documentDirURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        FileManager.default.createFile(atPath: (documentDirURL?.appendingPathComponent("eventData.csv", isDirectory: false).path)!,
                                       contents: "".data(using: String.Encoding.utf8))
        logEventDataFile = FileHandle(forUpdatingAtPath: documentDirURL!.appendingPathComponent("eventData.csv").path)

        FileManager.default.createFile(atPath: (documentDirURL?.appendingPathComponent("rawEventData.csv", isDirectory: false).path)!,
                                       contents: "".data(using: String.Encoding.utf8))
        logRawEventDataFile = FileHandle(forUpdatingAtPath: documentDirURL!.appendingPathComponent("rawEventData.csv").path)

        initialized = true
    }

    public func clearLogFiles() {
        logRawEventDataFile?.truncateFile(atOffset: 0)
        logEventDataFile?.truncateFile(atOffset: 0)
    }

    public func write(dataUploadRequest: DataUploadRequest) {
        if enabled {
            if !initialized {
                initialize()
            }

            guard case let .gps(gpsEvents) = dataUploadRequest.events else {
                return
            }

            for gd in gpsEvents {
                let logLine = "\(gd.latitude),\(gd.longitude),\(gd.accuracy),\(gd.timeFrom),\(gd.timeTo)\n"
                logEventDataFile?.seekToEndOfFile()
                logEventDataFile?.write(logLine.data(using: String.Encoding.utf8)!)
            }
        }
    }

    public func write(lat: Double, lon: Double, accuracy: Double, timestamp: Date) {
        if enabled {
            if !initialized {
                initialize()
            }

            let logLine = "\(lat),\(lon),\(accuracy),\(timestamp)\n"
            logRawEventDataFile?.seekToEndOfFile()
            logRawEventDataFile?.write(logLine.data(using: String.Encoding.utf8)!)
        }
    }
}
