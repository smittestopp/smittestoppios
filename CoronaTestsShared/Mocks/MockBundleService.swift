import Foundation
@testable import Smittestopp

class MockBundleService: BundleServiceProviding {
    var appConfigurationTarget: AppConfigurationTarget = .prod
    var gitCommit: String?
    var buildNumber: String?
    var appVersion: String = "99.88.77-mock"
    var onboarding: Onboarding?
    var privacyPolicyHTML: String?
}
