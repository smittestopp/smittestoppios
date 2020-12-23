import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import BackgroundTasks
import CoreLocation
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    let dependencies = DependencyContainer()
    static let uiTestingKeyPrefix = "UI-TestingKey_"
    let appRefreshTaskIdentifier = "website.heartbeat"

    lazy var mainViewController = MainViewController.instantiate(dependencies: dependencies)

    lazy var heartbeatManager = HeartbeatManager(
        dependencies: dependencies,
        minimumInterval: AppConfiguration.shared.heartbeatManager.minimumInterval)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if isUITestingEnabled {
            setUserDefaultsForUITesting()
        }

        // Override point for customization after application launch.
        MSAppCenter.start("MS-APP-CENTER-KEY", withServices: [
            MSAnalytics.self,
            MSCrashes.self,
        ])

        Analytics.shared.track(event: "appStarted")

        // Initialize NotificationService to handle notifications.
        _ = NotificationService.shared

        window = UIWindow(frame: UIScreen.main.bounds)
        updateRootViewController()
        window?.makeKeyAndVisible()

        NotificationCenter.default
            .addObserver(forName: NotificationType.BluetoothStateUpdated, object: nil, queue: nil) { notification in
            guard let oldValue = notification.userInfo?["old"] as? BluetoothState else {
                assertionFailure()
                return
            }
            let newValue = self.dependencies.locationManager.bluetoothState

            switch (oldValue.power, newValue.power) {
            case (.notDetermined, .off),
                 (.on, .off):
                NotificationService.shared.postBluetoothOff()
            case (.off, .on):
                NotificationService.shared.removeAllNotifications()
            default:
                break
            }
        }

        // Background fetch for iOS 12 and below
        let oneMinute: TimeInterval = 1 * 60
        application.setMinimumBackgroundFetchInterval(oneMinute)
        // Background fetch for iOS 13 and above
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: appRefreshTaskIdentifier,
                using: nil) { task in
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
            scheduleAppRefresh()
        }

        dependencies.dateOfBirthUploader.uploadIfNeeded()

        return true
    }

    @available(iOS 13.0, *)
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: appRefreshTaskIdentifier)
        request.earliestBeginDate = heartbeatManager.nextHeartbeatDate

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch let error as NSError {
            if error.domain == BGTaskScheduler.errorDomain {
                // These values come from BGTaskSchedulerErrorCode enum
                // defined in BGTaskScheduler.h
                // Unfortunately those are not bridged to Swift
                enum ErrorCode: Int {
                    case unavailable = 1
                    case tooManyPendingTaskRequests = 2
                    case notPermitted = 3
                }

                switch ErrorCode(rawValue: error.code) {
                case .unavailable:
                    Logger.info("Background app refresh unavailable", tag: "application")
                case .notPermitted:
                    Logger.info("Background app refresh not permitted", tag: "application")
                case .tooManyPendingTaskRequests:
                    Logger.info("Background app refresh failed due to too many tasks", tag: "application")
                case nil:
                    Logger.info("Background app refresh failed to schedule: \(error)", tag: "application")
                }
            } else {
                Logger.error("Background app refresh failed to schedule: \(error)", tag: "application")
            }
        } catch {
            Logger.error("Background app refresh failed to schedule: \(error)", tag: "application")
        }
    }

    @available(iOS 13.0, *)
    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()

        task.expirationHandler = {
            Logger.error("Background app refresh expired before completing", tag: "application")
            task.setTaskCompleted(success: false)
        }

        heartbeatManager.sendIfNeeded { result in
            switch result {
            case .failure(.notNeeded):
                task.setTaskCompleted(success: true)
            case .failure(.networkUnavailable),
                 .failure(.unknown):
                task.setTaskCompleted(success: false)
            case .success:
                task.setTaskCompleted(success: true)
            }
        }
    }

    func application(_: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        heartbeatManager.sendIfNeeded { result in
            switch result {
            case .failure(.notNeeded):
                completionHandler(.noData)
            case .failure(.networkUnavailable),
                 .failure(.unknown):
                completionHandler(.failed)
            case .success:
                completionHandler(.newData)
            }
        }
    }

    func applicationDidBecomeActive(_: UIApplication) {
        heartbeatManager.sendIfNeeded()
    }

    func applicationDidEnterBackground(_: UIApplication) {
        Logger.debug("CORONA: applicationDidEnterBackground", tag: "application")
    }

    func updateRootViewController() {
        window?.rootViewController = viewControllerForState(currentState())
    }

    private func currentState() -> RootState {
        guard dependencies.localStorage.hasAcceptedPrivacyPolicy else {
            return .onboarding
        }

        guard let user = dependencies.localStorage.user else {
            return .login
        }

        if user.deviceId == nil {
            guard user.expiresOn.timeIntervalSinceNow - LoginService.SECONDS_EARLIER_TOKEN_EXPIRES
                      > 0 else {
                return .expiredToken
            }
        }

        // all good we can show the main tab
        return .mainTab
    }

    private func viewControllerForState(_ state: RootState) -> UIViewController {
        let onboardingCompletionBlock = { [weak self] in
            self?.dependencies.localStorage.hasAcceptedPrivacyPolicy = true
            self?.updateRootViewController()
        }

        switch state {
        case .launch:
            return LaunchViewController()

        case .onboarding:
            let onboardingViewController = OnboardingViewController(
                dependencies: dependencies)
            onboardingViewController.didFinish = onboardingCompletionBlock
            return onboardingViewController

        case .login:
            let isEnoughPermissions = dependencies.locationManager.bluetoothState.isEnabled ||
                dependencies.locationManager.gpsState.isEnabled
            let onboardingViewController = OnboardingViewController(
                dependencies: dependencies,
                shouldShowRegistrationPage: isEnoughPermissions)
            onboardingViewController.didFinish = onboardingCompletionBlock
            return onboardingViewController

        case .expiredToken:
            let onboardingViewController = OnboardingViewController(
                dependencies: dependencies,
                shouldShowRegistrationPage: true,
                shouldShowTokenExpiredAlert: true)
            onboardingViewController.didFinish = onboardingCompletionBlock
            return onboardingViewController

        case .mainTab:
            return mainViewController
        }
    }

    private func setUserDefaultsForUITesting() {
        // Disable animations to speed up tests
        UIView.setAnimationsEnabled(false)
        window?.layer.speed = 100

        // Set UserDefault settings for testing
        for (key, value)
            in ProcessInfo.processInfo.environment
            where key.hasPrefix(AppDelegate.uiTestingKeyPrefix) {
            // Truncate "UI-TestingKey_" part
            let userDefaultsKey = key.truncateUITestingKey()
            if userDefaultsKey == "user" {
                dependencies.localStorage.user = LocalStorageService.User(
                    accessToken: "access-token",
                    expiresOn: Date().addingTimeInterval(3600),
                    phoneNumber: value,
                    deviceId: "device-id",
                    connectionString: "connection-string")
            } else {
                switch value {
                case "YES":
                    UserDefaults.standard.set(true, forKey: userDefaultsKey)
                case "NO":
                    UserDefaults.standard.set(false, forKey: userDefaultsKey)
                case "NONE":
                    UserDefaults.standard.removeObject(forKey: userDefaultsKey)
                default:
                    UserDefaults.standard.set(value, forKey: userDefaultsKey)
                }
            }
        }
    }
}

enum RootState {
    case launch
    case onboarding
    case login
    case expiredToken
    case mainTab
}

var isUITestingEnabled: Bool {
    CommandLine.arguments.contains("--UI-Testing")
}
