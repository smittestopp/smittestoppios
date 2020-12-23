import Foundation

class Logger {
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    static let shared: Logger = {
        let logger = Logger()
        #if DEBUG
        logger.addDestination(ConsoleDestination())
        logger.addDestination(LogfileDestination(.shared))
        #endif
        logger.addDestination(AppCenterAnalyticsDestination(analytics: .shared))
        return logger
    }()

    private var destinations: [LogDestination] = []

    func addDestination(_ destination: LogDestination) {
        destinations.append(destination)
    }

    func log(level: Logger.Level, message: String, tag: String?, properties: [String: String],
             file: StaticString, line: UInt) {
        destinations.forEach {
            $0.log(level: level, message: message, tag: tag, properties: properties, file: file, line: line)
        }
    }

    func error(_ msg: String, tag: String?, file: StaticString = #file, line: UInt = #line) {
        log(level: .error, message: msg, tag: tag, properties: [:], file: file, line: line)
    }

    func warning(_ msg: String, tag: String?, file: StaticString = #file, line: UInt = #line) {
        log(level: .warning, message: msg, tag: tag, properties: [:], file: file, line: line)
    }

    func info(_ msg: String, tag: String?, file: StaticString = #file, line: UInt = #line) {
        log(level: .info, message: msg, tag: tag, properties: [:], file: file, line: line)
    }

    func debug(_ msg: String, tag: String?, file: StaticString = #file, line: UInt = #line) {
        log(level: .debug, message: msg, tag: tag, properties: [:], file: file, line: line)
    }

    static func error(_ msg: String, tag: String?, file: StaticString = #file, line: UInt = #line) {
        Logger.shared.log(level: .error, message: msg, tag: tag, properties: [:], file: file, line: line)
    }

    static func warning(_ msg: String, tag: String?, file: StaticString = #file, line: UInt = #line) {
        Logger.shared.log(level: .warning, message: msg, tag: tag, properties: [:], file: file, line: line)
    }

    static func info(_ msg: String, tag: String?, file: StaticString = #file, line: UInt = #line) {
        Logger.shared.log(level: .info, message: msg, tag: tag, properties: [:], file: file, line: line)
    }

    static func debug(_ msg: String, tag: String?, file: StaticString = #file, line: UInt = #line) {
        Logger.shared.log(level: .debug, message: msg, tag: tag, properties: [:], file: file, line: line)
    }
}
