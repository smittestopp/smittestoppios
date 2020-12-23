import Foundation

protocol LogDestination {
    func log(level: Logger.Level, message: String, tag: String?, properties: [String: String],
             file: StaticString, line: UInt)
}
