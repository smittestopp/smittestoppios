import UIKit

class MainViewController: UITabBarController {
    typealias Dependencies = MonitoringViewController.Dependencies & SettingsViewController.Dependencies
    let dependencies: Dependencies

    lazy var monitoringVC = MonitoringViewController.instantiate(dependencies: dependencies)
    lazy var settingsVC = SettingsViewController.instantiate(dependencies: dependencies)
    let infoVC = InfoViewController.instantiate()

    static func instantiate(dependencies: Dependencies) -> MainViewController {
        return MainViewController(dependencies: dependencies)
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        view.backgroundColor = .appViewBackground
        tabBar.tintColor = .white
        tabBar.backgroundColor = .appButtonBackground
        tabBar.barTintColor = .appButtonBackground
        tabBar.isOpaque = true
        tabBar.isTranslucent = false

        setViewControllers([
            settingsVC,
            monitoringVC,
            infoVC,
        ], animated: false)

        // Select Monitoring tab by default
        selectedIndex = 1
    }

    override func viewDidAppear(_: Bool) {
        var tokenObserver: NSObjectProtocol?
        var deviceIdObserver: NSObjectProtocol?
        tokenObserver = NotificationCenter.default.addObserver(forName: NotificationType.TokenExpired, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                (UIApplication.shared.delegate as? AppDelegate)?.updateRootViewController()
            }
            if let observer = tokenObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        deviceIdObserver = NotificationCenter.default.addObserver(forName: IoTHubService.AccessRevoked, object: nil, queue: nil) { _ in
            self.dependencies.locationManager.setGPSEnabled(false)
            self.dependencies.locationManager.setBluetoothEnabled(false)
            self.dependencies.localStorage.clear()
            DispatchQueue.main.async {
                NotificationService.shared.postAccessRevoked()
                (UIApplication.shared.delegate as? AppDelegate)?.updateRootViewController()
            }
            if let observer = deviceIdObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}
