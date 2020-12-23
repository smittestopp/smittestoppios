import UIKit

/// Dedicated AppDelegate for running unit tests.
///
/// App is launches for unit testing we don't have to have all the side effect from the regular AppDelegate,
/// e.g. we do not want to sent analytics events or present real view controllers on screen. This class is
/// used as the UIApplication.shared.delegate
class AppDelegateForTesting: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
