import Foundation

protocol BundleServiceProviding: class {
    var appVersion: String { get }
    var appConfigurationTarget: AppConfigurationTarget { get }
    var gitCommit: String? { get }
    var buildNumber: String? { get }
    var onboarding: Onboarding? { get }
    var privacyPolicyHTML: String? { get }
}

protocol HasBundleService {
    var bundle: BundleServiceProviding { get }
}

class BundleService: BundleServiceProviding {
    enum PListKey {
        static let shortVersionString = "CFBundleShortVersionString"
        static let version = kCFBundleVersionKey as String

        static let appConfigurationTarget = "APP_CONFIGURATION_TARGET"
        static let gitCommit = "GIT_COMMIT"
    }

    let appVersion: String = Bundle.main.object(forInfoDictionaryKey: PListKey.shortVersionString) as! String

    let appConfigurationTarget: AppConfigurationTarget = {
        guard let appConfigurationTargetString = Bundle.main.object(forInfoDictionaryKey: PListKey.appConfigurationTarget) as? String else {
            fatalError("APP_CONFIGURATION not set in plist for this environment")
        }
        guard let target = AppConfigurationTarget(rawValue: appConfigurationTargetString) else {
            fatalError("APP_CONFIGURATION is invalid")
        }
        return target
    }()

    var gitCommit: String? {
        guard appConfigurationTarget == .releaseDev else {
            return nil
        }

        guard let gitCommit = Bundle.main.object(forInfoDictionaryKey: PListKey.gitCommit) as? String else {
            return nil
        }

        return gitCommit
    }

    var buildNumber: String? {
        guard appConfigurationTarget == .releaseDev else {
            return nil
        }

        guard let buildNumber = Bundle.main.object(forInfoDictionaryKey: PListKey.version) as? String else {
            return nil
        }

        return buildNumber
    }

    var onboarding: Onboarding? {
        guard
            let url = Bundle.main.url(forResource: "onboarding",
                                      withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let onboarding = try? JSONDecoder.standard.decode(Onboarding.self, from: data)
        else {
            return nil
        }

        return onboarding
    }

    var privacyPolicyHTML: String? {
        guard
            let url = Bundle.main.url(forResource: "privacyPolicy",
                                      withExtension: "html")
        else {
            return nil
        }

        return try? String(contentsOf: url)
    }
}
