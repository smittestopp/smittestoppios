import Foundation

class LogfileDestination: LogDestination {
    var logfile: Logfile

    init(_ logfile: Logfile) {
        self.logfile = logfile
    }

    func log(level: Logger.Level, message: String, tag: String?, properties _: [String : String], file _: StaticString, line _: UInt) {
        let tagOrEmpty = tag.map { "[\($0)] " } ?? ""
        let dateString: String = Utils.shared.formatDate(date: Date())
        logfile.write("\(dateString) \(level.rawValue): \(tagOrEmpty)\(message)\n")
    }
}
