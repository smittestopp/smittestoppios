import AppCenterAnalytics
import Foundation

class Analytics {
    static let shared: Analytics = {
        Analytics()
    }()

    private init() { }

    func track(event eventName: String, properties: [String: String] = [:]) {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"

        let standardProperties = [
            "v": appVersion,
        ]

        let allProperties = standardProperties.merging(properties) { current, _ in current }

        MSAnalytics.trackEvent(eventName, withProperties: allProperties)
    }
}
