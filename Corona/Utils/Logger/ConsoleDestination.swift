import Foundation

fileprivate extension Logger.Level {
    var symbol: String {
        switch self {
        case .debug:
            return "🐞DEBUG"
        case .info:
            return "ℹ️INFO"
        case .warning:
            return "⚠️WARN"
        case .error:
            return "💥ERROR"
        }
    }
}

class ConsoleDestination: LogDestination {
    let dateFormat: String = "yyyy-MM-dd HH:mm:ss.SSS"

    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = dateFormat
        return df
    }()

    func log(level: Logger.Level, message: String, tag: String?, properties _: [String: String],
             file _: StaticString, line _: UInt) {
        let tagOrEmpty = tag.map { "[\($0)] " } ?? ""

        let dateString: String = dateFormatter.string(from: Date())

        print("\(dateString) \(level.symbol): \(tagOrEmpty)\(message)")
    }
}
