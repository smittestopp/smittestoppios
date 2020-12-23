import Foundation

class AppCenterAnalyticsDestination: LogDestination {
    let analytics: Analytics

    init(analytics: Analytics) {
        self.analytics = analytics
    }

    func log(level: Logger.Level, message: String, tag _: String?, properties _: [String : String], file _: StaticString, line _: UInt) {
        switch level {
        case .info, .warning, .error:
            analytics.track(event: level.rawValue.lowercased(), properties: ["msg": message])
        case .debug:
            // Do not track this log message
            break
        }
    }
}
