import Foundation

public enum Environment {
    enum Keys {
        enum Plist {
            static let appConfigurationTarget = "APP_CONFIGURATION_TARGET"
        }
    }

    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict
    }()

    static let appConfigurationTarget: AppConfigurationTarget = {
        guard let appConfigurationTargetString = Environment.infoDictionary[Keys.Plist.appConfigurationTarget] as? String else {
            fatalError("APP_CONFIGURATION not set in plist for this environment")
        }
        guard let target = AppConfigurationTarget(rawValue: appConfigurationTargetString) else {
            fatalError("APP_CONFIGURATION is invalid")
        }
        return target
    }()
}
