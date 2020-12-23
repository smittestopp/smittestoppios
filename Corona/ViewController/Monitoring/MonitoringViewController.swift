import CoreBluetooth
import CoreLocation
import UIKit

fileprivate extension String {
    static let monitoring = "MonitoringVC"
}

enum LocationDisabledReason: Equatable {
    /// Location Services are globally disabled in System Settings
    case locationServicesDisabled
    /// Location authorization is not set to "Always" as we require
    case systemSettingsSetToAlways
}

enum BluetoothDisabledReason: Equatable {
    case globallyDisabled
    case systemSettingsSetToEnabled
}

extension GPSState {
    var reason: LocationDisabledReason? {
        if isLocationServiceEnabled {
            switch authorizationStatus {
            case .notDetermined:
                // When the user sets authorization to "Ask Next Time" the system tells us
                // that the status is .notDetermined
                return .systemSettingsSetToAlways
            case .enabledAlways:
                return nil
            case .denied, .restricted, .enabledWhenInUse:
                return .systemSettingsSetToAlways
            }
        } else {
            // Location service is turned off globally
            return .locationServicesDisabled
        }
    }
}

extension BluetoothState {
    var reason: BluetoothDisabledReason? {
        switch power {
        case .off:
            return .globallyDisabled
        case .on:
            break
        case .notDetermined:
            break
        }

        switch authorization {
        case .allowedAlways:
            return nil
        case .denied, .notDetermined, .restricted:
            return .systemSettingsSetToEnabled
        }
    }
}

class MonitoringViewController: UIViewController, UITextFieldDelegate {
    typealias Dependencies = HasLocalStorageService & HasLocationManager & HasIoTHubService & HasDateOfBirthUploader
    let dependencies: Dependencies
    let ageLimit = 16

    static func instantiate(dependencies: Dependencies) -> UIViewController {
        let vc = MonitoringViewController(dependencies: dependencies)
        vc.tabBarItem = UITabBarItem(title: "Tab.Monitoring".localized, image: UIImage(named: "tab-monitoring"), tag: 0)
        vc.tabBarItem.accessibilityIdentifier = "monitoringTab"
        return vc
    }

    enum State: Equatable {
        case fullyActivated
        case bluetoothOff(BluetoothDisabledReason)
        case locationOff(LocationDisabledReason)
        case deactivated(location: LocationDisabledReason, bluetooth: BluetoothDisabledReason)
        case deactivatedByUser
    }

    var state: State = .fullyActivated {
        didSet {
            guard oldValue != state else {
                return
            }
            stateChanged()
        }
    }

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    let headerView = MonitoringHeaderView()
    let authorizationView = MonitoringAuthorizationsView()
    let instructionsView = MonitoringInstructionsView()
    lazy var registerAgeView: MonitoringAgeVerificationView = {
        let view = MonitoringAgeVerificationView()
        view.registerAgeButtonTapped = { [weak self] in
            self?.registerAge()
        }
        view.explanationButtonTapped = { [weak self] in
            self?.showExplanationAlert()
        }
        return view
    }()
    lazy var shareAppView: MonitoringShareAppView = {
        let view = MonitoringShareAppView()
        view.shareButtonTapped = { [weak self] in
            self?.shareApplicationLink()
        }
        return view
    }()
    lazy var restartMonitoringView: MonitoringRestartView = {
        let view = MonitoringRestartView()
        view.restartButtonTapped = { [weak self] in
            self?.restartMonitoring()
        }
        return view
    }()

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
        view.accessibilityIdentifier = "monitoringView"

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        let horizontalMargin: CGFloat = 40

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: horizontalMargin),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -horizontalMargin),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -horizontalMargin * 2),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dependencies.iotHubService.start()
        dependencies.dateOfBirthUploader.uploadIfNeeded()

        [
            NotificationType.GPSStateUpdated,
            NotificationType.BluetoothStateUpdated,
            NotificationType.TrackingConsentUpdated,
        ].forEach { name in
            NotificationCenter.default
                .addObserver(forName: name, object: nil, queue: nil) { [weak self] _ in
                    self?.updateStateFromTrackingPermissions()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NotificationType.DeviceProvisioned,
            object: nil,
            queue: nil) { [weak self] _ in
                self?.dependencies.iotHubService.start()
                self?.dependencies.dateOfBirthUploader.uploadIfNeeded()
        }

        NotificationCenter.default
            .addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
                // when coming from background it is possible that the user has changed permissions to "Ask next time".
                self?.askForPermissionsIfNeeded()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: nil) { [weak self] _ in
            self?.updateAgeVerificationButtonText()
        }

        askForPermissionsIfNeeded()

        stateChanged()

        updateStateFromTrackingPermissions()

        registerAgeView.ageVerificationField.delegate = self
    }

    private func updateAgeVerificationButtonText() {
        registerAgeView.ageVerificationButton.setTitle()
    }

    func textField(_: UITextField, shouldChangeCharactersIn _: NSRange, replacementString _: String) -> Bool {
        // Make textField tappable, but not editable
        false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        askForPermissionsIfNeeded()
    }

    private func askForPermissionsIfNeeded() {
        dependencies.locationManager.setGPSEnabled(dependencies.localStorage.isTrackingEnabled)
        dependencies.locationManager.setBluetoothEnabled(dependencies.localStorage.isTrackingEnabled)
    }

    private func updateStateFromTrackingPermissions() {
        let gpsState = dependencies.locationManager.gpsState
        let bluetoothState = dependencies.locationManager.bluetoothState

        guard dependencies.localStorage.isTrackingEnabled else {
            state = .deactivatedByUser
            return
        }

        switch (gpsState.isEnabled, bluetoothState.isEnabled) {
        case (true, true):
            state = .fullyActivated

        case (false, true):
            guard let reason = gpsState.reason else {
                Logger.error("Failed to detect disabled reason: \(gpsState)", tag: .monitoring)
                return
            }
            state = .locationOff(reason)

        case (true, false):
            guard let reason = bluetoothState.reason else {
                Logger.error("Failed to detect disabled reason: \(bluetoothState)", tag: .monitoring)
                return
            }
            state = .bluetoothOff(reason)

        case (false, false):
            switch (gpsState.reason, bluetoothState.reason) {
            case (.some(let location), .some(let bluetooth)):
                state = .deactivated(location: location, bluetooth: bluetooth)

            case (.some(let reason), .none):
                state = .locationOff(reason)

            case (.none, .some(let reason)):
                state = .bluetoothOff(reason)

            case (.none, .none):
                Logger.error("Failed to detect disabled reason: \(gpsState) \(bluetoothState)", tag: .monitoring)
            }
        }
    }

    private func stateChanged() {
        let views: [UIView]

        switch state {
        case .fullyActivated:
            headerView.state = .working

            views = [
                headerView,
                MonitoringThankYouView(),
                dependencies.localStorage.dateOfBirth == nil
                    ? registerAgeView
                    : shareAppView,
            ]

        case let .bluetoothOff(reason):
            headerView.state = .partiallyWorking

            authorizationView.isGpsOn = true
            authorizationView.isBluetoothOn = false

            instructionsView.instructionType = .bluetooth(reason)

            views = [
                headerView,
                authorizationView,
                dependencies.localStorage.dateOfBirth == nil
                    ? registerAgeView
                    : instructionsView,
            ]

        case let .locationOff(reason):
            headerView.state = .partiallyWorking

            authorizationView.isGpsOn = false
            authorizationView.isBluetoothOn = true

            instructionsView.instructionType = .location(reason)

            views = [
                headerView,
                authorizationView,
                dependencies.localStorage.dateOfBirth == nil
                    ? registerAgeView
                    : instructionsView,
            ]

        case let .deactivated(locationReason, bluetoothReason):
            headerView.state = .notWorking

            authorizationView.isGpsOn = false
            authorizationView.isBluetoothOn = false

            instructionsView.instructionType = .both(locationReason, bluetoothReason)

            views = [
                headerView,
                authorizationView,
                dependencies.localStorage.dateOfBirth == nil
                    ? registerAgeView
                    : instructionsView,
            ]

        case .deactivatedByUser:
            headerView.state = .deactivated

            views = [
                headerView,
                dependencies.localStorage.dateOfBirth == nil
                    ? registerAgeView
                    : restartMonitoringView,
            ]
        }

        stackView.removeAllArrangedSubviews()
        views.forEach(stackView.addArrangedSubview(_:))
    }

    private func shareApplicationLink() {
        guard let appUrl = URL(string: AppConfiguration.shared.appStoreWebUrl) else {
            return
        }

        let activityVC = UIActivityViewController(activityItems: [appUrl], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }

    private func restartMonitoring() {
        dependencies.localStorage.isTrackingEnabled = true
        dependencies.locationManager.setGPSEnabled(true)
        dependencies.locationManager.setBluetoothEnabled(true)
    }

    private func showExplanationAlert() {
        presentAgeVerificationExplanationAlert()
    }

    private func registerAge() {
        registerAgeView.ageVerificationField.resignFirstResponder()

        let selectedDate = registerAgeView.ageVerificationField.datePicker.date

        guard let difference = Date().years(sinceDate: selectedDate), difference >= ageLimit else {
            presentAgeVerificationInvalidAgeAlert()
            Logger.warning("Failed to validate age", tag: .monitoring)
            return
        }
        dependencies.localStorage.dateOfBirth = YearMonthDay(selectedDate)
        dependencies.dateOfBirthUploader.uploadIfNeeded()
        stateChanged()

        let localizedDateAsString: String = {
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .none
            return df.string(from: selectedDate)
        }()
        presentAgeVerificationConfirmationAlert(localizedDateAsString)

        Logger.info("Age was successfully validated", tag: .monitoring)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let tabBarHeight = tabBarController?.tabBar.frame.size.height ?? 0
            view.frame.origin.y = tabBarHeight - keyboardSize.height
        }
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
        view.frame.origin.y = 0
    }
}

// Unused, but see reference for possible way of getting MAC address from Bluetooth LE devices (unverified)
// https://stackoverflow.com/a/57708903
extension Data {
    func hexEncodedString() -> String {
        let hexDigits = Array("0123456789abcdef".utf16)
        var hexChars = [UTF16.CodeUnit]()
        hexChars.reserveCapacity(count * 2)

        for byte in self {
            let (index1, index2) = Int(byte).quotientAndRemainder(dividingBy: 16)
            hexChars.insert(hexDigits[index2], at: 0)
            hexChars.insert(hexDigits[index1], at: 0)
        }
        return String(utf16CodeUnits: hexChars, count: hexChars.count)
    }
}

extension String {
    func separate(every stride: Int = 4, with separator: Character = " ") -> String {
        return String(enumerated().map {
            $0 > 0 && $0 % stride == 0 ? [separator, $1] : [$1]
        }.joined())
    }
}
