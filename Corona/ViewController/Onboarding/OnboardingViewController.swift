import UIKit

fileprivate extension String {
    static let onboarding = "OnboardingVC"
}

typealias DidFinishBlock = (() -> Void)
typealias LoginLoadingState = LoadingState<Void, LoginService.Error>

protocol OnboardingPagePresenter: class {
    var page: OnboardingPage { get set }
}

class OnboardingViewController: UIViewController, PagingViewControllerDelegate {
    typealias Dependencies =
        HasLoginService & HasLocationManager &
        HasLocalStorageService &
        HasBundleService &
        PermissionsViewController.PermissionsDependencies &
        OnboardingAgeVerificationViewController.AgeVerificationDependencies
    let dependencies: Dependencies

    var pagingViewController: PagingViewController?

    var didFinish: DidFinishBlock?

    var shouldShowRegistrationPage: Bool

    var shouldShowTokenExpiredAlert: Bool

    init(dependencies: Dependencies,
         shouldShowRegistrationPage: Bool = false,
         shouldShowTokenExpiredAlert: Bool = false) {
        self.dependencies = dependencies
        self.shouldShowRegistrationPage = shouldShowRegistrationPage
        self.shouldShowTokenExpiredAlert = shouldShowTokenExpiredAlert
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .appViewBackground
        view.accessibilityIdentifier = "onboardingView"

        guard
            let onboarding = dependencies.bundle.onboarding,
            !onboarding.pages.isEmpty
        else {
            return
        }

        show(onboarding)

        if shouldShowRegistrationPage {
            let numberOfPages = onboarding.pages.count - 1
            pagingViewController?.goToPageAtIndex(numberOfPages, animated: false)
        }

        observeNotifications()
    }

    override func viewDidAppear(_: Bool) {
        if shouldShowTokenExpiredAlert {
            showTokenExpiredAlert()
            shouldShowTokenExpiredAlert = false
        }
    }

    func showTokenExpiredAlert() {
        let alertVC = UIAlertController(
            title: "Onboarding.TokenExpired.Title".localized,
            message: "Onboarding.TokenExpired.Description".localized,
            preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(
            title: "ConfirmButton.Title".localized,
            style: .default, handler: { _ in
                self.dependencies.localStorage.user = nil
            }))
        present(alertVC, animated: true, completion: nil)
    }

    private func viewControllerForPage(_ page: OnboardingPage) -> UIViewController {
        switch page.type {
        case .permissions:
            return PermissionsViewController(dependencies: dependencies, page: page) { [weak self] in
                self?.handleButtonAction(page.buttonAction)
            }
        case .ageVerification:
            return OnboardingAgeVerificationViewController(dependencies:dependencies, page: page) { [weak self] in
                self?.handleButtonAction(page.buttonAction)
            }
        default:
            return OnboardingPageRendererViewController(page) { [weak self] buttonAction in
                self?.handleButtonAction(buttonAction)
            }
        }
    }

    func show(_ onboarding: Onboarding) {
        pagingViewController?.remove()

        let viewControllers = onboarding.pages.map { viewControllerForPage($0) }

        let viewController = PagingViewController(viewControllers: viewControllers)
        viewController.delegate = self
        viewController.pageControl.pageIndicatorTintColor = .gray
        viewController.pageControl.currentPageIndicatorTintColor = .blue
        pagingViewController = viewController
        viewController.didFinish = didFinish
        install(viewController)
    }

    func handleButtonAction(_ action: OnboardingButtonAction) {
        switch action {
        case .next:
            pagingViewController?.goToNextPage()
        case .privacyPolicy:
            showPrivacyPolicy()
        case .register:
            signIn()
        }
    }

    private func signIn() {
        setLoadingState(LoginLoadingState.loading)

        let loginService = dependencies.loginService

        loginService.signIn(on: self) { result in
            switch result {
            case let .success(res):
                self.setLoadingState(LoginLoadingState.loaded(()))

                DispatchQueue.main.async {
                    loginService.attemptDeviceRegistration()
                }
                let user = LocalStorageService.User(
                    accessToken: res.accessToken, expiresOn: res.expiresOn, phoneNumber: res.phoneNumber,
                    deviceId: nil,
                    connectionString: nil)
                self.dependencies.localStorage.user = user
                self.didFinish?()
            case let .failure(error):
                if case .userCancelled = error {
                    // User cancelled logging in, not an error, just ignore this.
                    self.setLoadingState(LoginLoadingState.loaded(()))
                    return
                }

                self.setLoadingState(LoginLoadingState.failed(error))

                Logger.error("Failed to sign in: \(error)", tag: .onboarding)
            }
        }
    }

    func showPrivacyPolicy() {
        guard let privacyPolicyHTML = dependencies.bundle.privacyPolicyHTML else {
            return
        }

        let acceptBlock = { [weak self] in
            self?.dependencies.localStorage.hasAcceptedPrivacyPolicy = true
            self?.dismiss(animated: true, completion: {
                self?.pagingViewController?.goToNextPage()
            })
        }

        let denyBlock = { [weak self] in
            let alertVC = UIAlertController(
                title: "PrivacyPolicy.DeclineConfirmation.Title".localized,
                message: "PrivacyPolicy.DeclineConfirmation.Description".localized,
                preferredStyle: .alert)

            alertVC.addAction(UIAlertAction(title: "PrivacyPolicy.DeclineConfirmation.DeclineButton.Title".localized, style: .destructive, handler: { _ in
                self?.dependencies.localStorage.hasAcceptedPrivacyPolicy = false
                self?.dismiss(animated: true, completion: {
                    self?.pagingViewController?.goToPageAtIndex(0)
                })
            }))

            alertVC.addAction(UIAlertAction(title: "PrivacyPolicy.DeclineConfirmation.AcceptButton.Title".localized, style: .default, handler: { _ in
                acceptBlock()
            }))

            self?.presentedViewController?.present(alertVC, animated: true)
        }

        let privacyPolicyViewController = OnboardingPrivacyPolicyViewController(
            privacyPolicyHTML: privacyPolicyHTML,
            acceptBlock: acceptBlock,
            denyBlock: denyBlock)

        present(privacyPolicyViewController, animated: true)
    }

    func pagingViewController(_: PagingViewController,
                              canContinueFrom viewController: UIViewController,
                              fromIndex _: Int) -> Bool {
        guard let onboardingPageViewController = viewController as? OnboardingPagePresenter else {
            return true
        }

        switch onboardingPageViewController.page.type {
        case .page:
            return true
        case .privacy:
            return dependencies.localStorage.hasAcceptedPrivacyPolicy
        case .ageVerification:
            return dependencies.localStorage.dateOfBirth != nil
        case .permissions:
            let bluetoothEnabled = dependencies.locationManager.bluetoothState.isEnabled
            let gpsEnabled = dependencies.locationManager.gpsState.isDetermined
            return bluetoothEnabled || gpsEnabled
        case .register:
            return true
        }
    }

    private func observeNotifications() {
        let notifications = [NotificationType.GPSStateUpdated, NotificationType.BluetoothStateUpdated]

        notifications.forEach { notification in
            NotificationCenter.default
                .addObserver(forName: notification, object: nil, queue: nil) { [weak self] _ in
                    self?.pagingViewController?.refresh()
            }
        }
    }
}
