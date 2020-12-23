import UIKit

fileprivate extension String {
    static let settings = "SettingsVC"
}

class SettingsViewController: UIViewController {
    typealias Dependencies =
        HasLoginService &
        HasLocalStorageService &
        HasBundleService &
        HasApiService &
        HasLocationManager &
        HasIoTHubService &
        HasOfflineStore &
        HasBLEIdentifierService
    let dependencies: Dependencies

    static func instantiate(dependencies: Dependencies) -> UIViewController {
        let vc = SettingsViewController(dependencies: dependencies)
        vc.tabBarItem = UITabBarItem(title: "Tab.Settings".localized, image: UIImage(named: "tab-settings"), tag: 0)
        vc.tabBarItem.accessibilityIdentifier = "settingsTab"
        return UINavigationController(rootViewController: vc)
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.backgroundColor = .appViewBackground
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension

        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(SettingsTitleCell.self)
        tableView.register(SettingsSupportCell.self)
        tableView.register(SettingsAuthorizationsCell.self)
        tableView.register(SettingsUserCell.self)
        tableView.register(SettingsNotificationCell.self)
        tableView.register(SettingsDeleteDataCell.self)

        return tableView
    }()

    enum Section: Int, CaseIterable {
        case title
        case user
        case authorizations
        case support
        case notifications
        case deleteData
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
        view.accessibilityIdentifier = "settingsView"
        [
            tableView,
        ].forEach(view.addSubview(_:))

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        [
            NotificationType.GPSStateUpdated,
            NotificationType.BluetoothStateUpdated,
            NotificationType.TrackingConsentUpdated,
        ].forEach { name in
            NotificationCenter.default
                .addObserver(forName: name, object: nil, queue: nil) { [weak self] _ in
                self?.reloadTableViewData()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    private func logout() {
        dependencies.locationManager.setGPSEnabled(false)
        dependencies.locationManager.setBluetoothEnabled(false)

        deleteAllLocalData()
        navigateToOnboarding()
    }

    private func showAlert(title: String?, message: String) {
        let alertVC = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OKButton.Title".localized, style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }

    private func deleteAllDataAndLogout() {
        setLoadingState(LoginLoadingState.loading)
        dependencies.locationManager.setGPSEnabled(false)
        dependencies.locationManager.setBluetoothEnabled(false)

        dependencies.loginService.signIn(on: self) { [weak self] result in
            switch result {
            case let .success(res):
                let accessToken = res.accessToken

                self?.dependencies.apiService.sendDataDeletionRequest(accessToken: accessToken) { result in
                    self?.setLoadingState(LoginLoadingState.loaded(()))
                    if case let .failure(error) = result {
                        Logger.error("Failed to trigger data deletion: \(error)", tag: .settings)
                        self?.showAlert(title: nil, message: "Settings.DeleteAllMyDataError".localized)
                        return
                    }

                    self?.deleteAllLocalData()
                    self?.navigateToOnboarding()
                }

            case let .failure(error):
                self?.setLoadingState(LoginLoadingState.loaded(()))
                if case .userCancelled = error {
                    return
                }
                Logger.error("Failed to sign in: \(error)", tag: .settings)
                self?.showAlert(title: nil, message: "Settings.DeleteAllMyDataError".localized)
            }
        }
    }

    private func deleteAllLocalData() {
        dependencies.localStorage.clear()

        dependencies.offlineStore.removeAllData()
        dependencies.iotHubService.stop()
        dependencies.bleIdentifierService.clear()
    }

    private func navigateToOnboarding() {
        (UIApplication.shared.delegate as? AppDelegate)?.updateRootViewController()
    }

    private func confirmDataDeletion() {
        let alertVC = UIAlertController(
            title: "Settings.DeleteAllMyDataConfirmation.Title".localized,
            message: "Settings.DeleteAllMyDataConfirmation.Message".localized,
            preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(
            title: "CancelButton.Title".localized,
            style: .cancel, handler: nil))
        alertVC.addAction(UIAlertAction(
            title: "DeleteButton.Title".localized,
            style: .destructive, handler: { _ in
            self.deleteAllDataAndLogout()
        }))
        present(alertVC, animated: true, completion: nil)
    }

    private func confirmLogout() {
        let alertVC = UIAlertController(
            title: "Settings.User.Logout.Title".localized,
            message: "Settings.User.Logout.Message".localized,
            preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(
            title: "CancelButton.Title".localized,
            style: .cancel, handler: nil))
        alertVC.addAction(UIAlertAction(
            title: "OKButton.Title".localized,
            style: .default, handler: { _ in
            self.logout()
        }))
        present(alertVC, animated: true, completion: nil)
    }

    private func reloadTableViewData() {
        tableView.reloadData()
    }

    private func secretTap() {
        guard let deviceId = dependencies.localStorage.user?.deviceId else {
            return
        }

        let pasteboard = UIPasteboard.general
        pasteboard.string = deviceId

        // make a little visual cue that something happened
        let cell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.user.rawValue))
        cell?.alpha = 0.5
        UIView.animate(withDuration: 0.2) {
            cell?.alpha = 1
        }
    }

    private func getPrivacyPolicyHTML() -> String {
        guard let privacyPolicyHTML = dependencies.bundle.privacyPolicyHTML else {
            return ""
        }

        return privacyPolicyHTML
    }

    private func getNotificationPinCodes(cell: SettingsNotificationCell) {
        dependencies.apiService.getPinCodes { result in
            switch result {
            case let .success(data):
                var pinCodes = data.pinCodes
                pinCodes.sort(by: { $0.createdAt > $1.createdAt })
                let pinCodeLabels = self.getPinCodeLabels(pinCodes)
                cell.pinCodeStackView.removeAllArrangedSubviews()
                pinCodeLabels.forEach(cell.pinCodeStackView.addArrangedSubview(_:))
                self.reloadTableViewData()
                Logger.info("Successfully fetched pin codes", tag: .settings)
            case let .failure(error):
                Logger.error("Failed to fetch pin codes: \(error.localizedDescription)", tag: .settings)
            }
        }
    }

    func getPinCodeLabels(_ pinCodes: [ApiService.PinCodeResponse.PinCode]) -> [UIView] {
        let pinCodeLabels = pinCodes.map { (pinCode) -> UIView in
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.adjustsFontForContentSizeCategory = true
            label.font = .custom(.bold, size: 18, forTextStyle: .body)
            label.textAlignment = .left
            label.textColor = .appMainText
            label.text = "\(pinCode.pinCode)\n"
            return label
        }

        return pinCodeLabels
    }

    private func showPrivacyPolicy() {
        let privacyPolicyHTML = getPrivacyPolicyHTML()

        let testViewController = SettingsPrivacyPolicyViewController(privacyPolicyHTML: privacyPolicyHTML)

        present(testViewController, animated: true)
    }
}

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .title:
            let versionString: String = {
                let appVersionString = "v\(dependencies.bundle.appVersion)"

                guard
                    // only defined for dev builds
                    let gitCommit = dependencies.bundle.gitCommit,
                    let buildNumber = dependencies.bundle.buildNumber
                else {
                    return appVersionString
                }

                return """
                  \(appVersionString)
                  build number: \(buildNumber)
                  git: \(gitCommit)
                  """
            }()

            let cell = tableView.dequeue(indexPath, SettingsTitleCell.self)
            cell.versionString = versionString

            return cell
        case .user:
            let cell = tableView.dequeue(indexPath, SettingsUserCell.self)
            cell.phoneNumber = dependencies.localStorage.user?.phoneNumber ?? " "
            cell.logoutButtonTapped = { [weak self] in
                self?.confirmLogout()
            }
            cell.secretTapped = { [weak self] in
                self?.secretTap()
            }
            cell.privacyTapped = { [weak self] in
                self?.showPrivacyPolicy()
            }
            return cell
        case .authorizations:
            let cell = tableView.dequeue(indexPath, SettingsAuthorizationsCell.self)
            cell.isOn = dependencies.localStorage.isTrackingEnabled
            cell.monitoringToggled = { [weak self] isOn in
                self?.dependencies.localStorage.isTrackingEnabled = isOn
                self?.dependencies.locationManager.setGPSEnabled(isOn)
                self?.dependencies.locationManager.setBluetoothEnabled(isOn)
            }
            return cell
        case .support:
            return tableView.dequeue(indexPath, SettingsSupportCell.self)
        case .notifications:
            let cell = tableView.dequeue(indexPath, SettingsNotificationCell.self)
            cell.showValidationCodeTapped = { [weak self] in
                self?.getNotificationPinCodes(cell: cell)
            }
            return cell
        case .deleteData:
            let cell = tableView.dequeue(indexPath, SettingsDeleteDataCell.self)
            cell.deleteButtonTapped = { [weak self] in
                self?.confirmDataDeletion()
            }
            #if DEBUG
            cell.secretTapActivated = { [weak self] in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "UploadStats")
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            #endif
            return cell
        case .none:
            assertionFailure()
            return UITableViewCell()
        }
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 0
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 0
    }

    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        return nil
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        return nil
    }
}
