import UIKit

let isUnitTesting = NSClassFromString("XCTestCase") != nil
let appDelegateClass: AnyClass = isUnitTesting ? AppDelegateForTesting.self : AppDelegate.self

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(appDelegateClass)
)
