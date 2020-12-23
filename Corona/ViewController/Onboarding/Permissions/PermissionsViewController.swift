import UIKit

class PermissionsViewController: UIViewController, OnboardingPagePresenter {
    typealias PermissionsDependencies = HasLocationManager & HasNotificationService
    let dependencies: PermissionsDependencies

    var page: OnboardingPage

    var buttonAction: (() -> ()) = { }

    // need to keep track of a denial for later checks, as we won't get any more notifications
    var didDenyLocationPermission: Bool = false
    var didDenyBluetoothPermission: Bool = false

    var canGoToNextPage: Bool {
        dependencies.locationManager.gpsState.isEnabled ||
        dependencies.locationManager.bluetoothState.isEnabled
    }

    lazy var pageViewController = OnboardingPageViewController(buttonAction: buttonAction)

    init(dependencies: PermissionsDependencies, page: OnboardingPage, buttonAction: @escaping () -> ()) {
        self.dependencies = dependencies
        self.page = page
        self.buttonAction = buttonAction

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .appViewBackground

        install(pageViewController)
        pageViewController.button.setTitle(page.buttonText, for: .normal)
        pageViewController.button.isEnabled = canGoToNextPage
        pageViewController.button.accessibilityIdentifier = page.buttonIdentifier
        render()
    }

    private func requestLocationPermissions(_ button: PermissionActionButton) {
        // check if it was previously denied, as we won't get notifications the third time around
        guard didDenyLocationPermission == false else {
            presentErrorAlert(setting: "Location")
            return
        }

        NotificationCenter.default.addObserver(
            forName: NotificationType.GPSStateUpdated, object: nil, queue: nil
        ) { [weak self] token in
            guard let strongSelf = self else { return }

            let gps = strongSelf.dependencies.locationManager.gpsState

            switch gps.authorizationStatus {
            case .denied, .restricted:
                self?.didDenyLocationPermission = true
                self?.presentErrorAlert(setting: "Location")
            case .notDetermined:
                assertionFailure()
                fallthrough
            case .enabledAlways, .enabledWhenInUse:
                button.setStyle(.allowed, animated: true)
                button.isEnabled = false
                strongSelf.pageViewController.button.isEnabled = true
            }

            NotificationCenter.default.removeObserver(token)
        }

        dependencies.locationManager.setGPSEnabled(true)
    }

    private func requestBluetoothPermissions(_ button: PermissionActionButton) {
        // check if it was previously denied, as we won't get notifications the third time around
        guard didDenyBluetoothPermission == false else {
            presentErrorAlert(setting: "Bluetooth")
            return
        }

        NotificationCenter.default.addObserver(
            forName: NotificationType.BluetoothStateUpdated, object: nil, queue: nil
        ) { [weak self] token in
            guard let strongSelf = self else { return }

            if strongSelf.dependencies.locationManager.bluetoothState.isEnabled {
                button.setStyle(.allowed, animated: true)
                button.isEnabled = false
                strongSelf.pageViewController.button.isEnabled = true
            } else if strongSelf.dependencies.locationManager.bluetoothState.authorization == .denied {
                self?.didDenyBluetoothPermission = true
                self?.presentErrorAlert(setting: "Bluetooth")
            }

            NotificationCenter.default.removeObserver(token)
        }

        dependencies.locationManager.setBluetoothEnabled(true)
    }

    private func requestNotificationsPermissions(_ button: PermissionActionButton) {
        dependencies.notificationService.requestAuthorization { [weak self] result in
            switch result {
            case .success:
                button.setStyle(.allowed, animated: true)
                button.isEnabled = false
            case .failure(.notGranted):
                self?.presentErrorAlert(setting: "Notifications")
            case let .failure(error):
                Logger.debug(error.localizedDescription, tag: nil)
                break
            }
        }
    }

    func render() {
        let stackView = pageViewController.stackView
        stackView.removeAllArrangedSubviews()

        let headerView = PermissionHeaderView()
        stackView.addArrangedSubview(headerView)
        stackView.setCustomSpacing(20, after: headerView)

        // Location Permissions
        let location: PermissionItemView = {
            let isEnabled = dependencies.locationManager.gpsState.isEnabled

            let item = PermissionItemView()
            item.title = "Onboarding.Permissions.Location.Title".localized
            item.text = "Onboarding.Permissions.Location.Description".localized
            item.image = UIImage(named: "permission_location")!

            item.buttonAction = { [weak self] button in
                self?.requestLocationPermissions(button)
            }
            item.button.setStyle(isEnabled ? .allowed : .base, animated: false)
            item.button.allowTitle = "Onboarding.Permissions.AllowButton.Title".localized
            item.button.allowedTitle = "Onboarding.Permissions.AlreadyAllowedButton.Title".localized
            item.button.allowAccessibilityLabel = "Onboarding.Permissions.AllowButton.LocationAccessibilityLabel".localized
            item.button.allowedAccessibilityLabel = "Onboarding.Permissions.AlreadyAllowedButton.LocationAccessibilityLabel".localized
            item.button.allowAccessibilityIdentifier = "permissionsLocationButtonAllow"
            item.button.allowedAccessibilityIdentifier = "permissionsLocationButtonAllowed"

            return item
        }()
        addConstraints(on: location, stackView: stackView)

        // Bluetooth Permissions
        let bluetooth: PermissionItemView = {
            let isEnabled = dependencies.locationManager.bluetoothState.isEnabled

            let item = PermissionItemView()
            item.title = "Onboarding.Permissions.Bluetooth.Title".localized
            item.text = "Onboarding.Permissions.Bluetooth.Description".localized
            item.image = UIImage(named: "permission_bluetooth")!

            item.buttonAction = { [weak self] button in
                self?.requestBluetoothPermissions(button)
            }

            item.button.setStyle(isEnabled ? .allowed : .base, animated: false)
            item.button.allowTitle = "Onboarding.Permissions.AllowButton.Title".localized
            item.button.allowedTitle = "Onboarding.Permissions.AlreadyAllowedButton.Title".localized
            item.button.allowAccessibilityLabel = "Onboarding.Permissions.AllowButton.BluetoothAccessibilityLabel".localized
            item.button.allowedAccessibilityLabel = "Onboarding.Permissions.AlreadyAllowedButton.BluetoothAccessibilityLabel".localized
            item.button.allowAccessibilityIdentifier = "permissionsBluetoothButtonAllow"
            item.button.allowedAccessibilityIdentifier = "permissionsBluetoothButtonAllowed"

            return item
        }()
        addConstraints(on: bluetooth, stackView: stackView)

        // Notifications Permissions
        let notifications: PermissionItemView = {
            let isEnabled = dependencies.notificationService.authorizationStatus.isAuthorized

            let item = PermissionItemView()
            item.title = "Onboarding.Permissions.Notifications.Title".localized
            item.text = "Onboarding.Permissions.Notifications.Description".localized
            item.image = UIImage(named: "permission_notification")!

            item.buttonAction = { [weak self] button in
                self?.requestNotificationsPermissions(button)
            }

            item.button.setStyle(isEnabled ? .allowed : .base, animated: false)
            item.button.allowTitle = "Onboarding.Permissions.AllowButton.Title".localized
            item.button.allowedTitle = "Onboarding.Permissions.AlreadyAllowedButton.Title".localized
            item.button.allowAccessibilityLabel = "Onboarding.Permissions.AllowButton.NotificationsAccessibilityLabel".localized
            item.button.allowedAccessibilityLabel = "Onboarding.Permissions.AlreadyAllowedButton.NotificationsAccessibilityLabel".localized
            item.button.allowAccessibilityIdentifier = "permissionsNotificationsButtonAllow"
            item.button.allowedAccessibilityIdentifier = "permissionsNotificationsButtonAllowed"

            return item
        }()
        addConstraints(on: notifications, stackView: stackView)
    }

    func addConstraints(on item: PermissionItemView, stackView: UIStackView) {
        stackView.addArrangedSubview(item)
        item.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
        item.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
        stackView.setCustomSpacing(20, after: item)
    }

    func settingsURL() -> URL? {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settingsUrl) else {
            return nil
        }

        return settingsUrl
    }

    func presentErrorAlert(setting: String) {
        let alertController = UIAlertController(title: "Onboarding.Permissions.NotEnoughPermissions.Title".localized,
                                                message: "Onboarding.Permissions.NotEnoughPermissions.\(setting)".localized,
                                                preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "OKButton.Title".localized, style: .default, handler: nil)
        alertController.addAction(cancelAction)

        if let settingsURL = settingsURL() {
            let settingsAction = UIAlertAction(title: "Onboarding.Permissions.NotEnoughPermissions.GoToSettingsButton.Title".localized,
                style: .default) { (_) -> Void in
                UIApplication.shared.open(settingsURL, completionHandler: { _ in })
            }
            alertController.addAction(settingsAction)
        }

        present(alertController, animated: true, completion: nil)
    }
}
