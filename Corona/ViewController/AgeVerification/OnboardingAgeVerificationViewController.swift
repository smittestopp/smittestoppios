import UIKit

fileprivate extension String {
    static let onboardingAgeVerification = "OnboardingAgeVerificationVC"
}

class OnboardingAgeVerificationViewController: UIViewController, OnboardingPagePresenter {
    typealias AgeVerificationDependencies = HasLocalStorageService
    let dependencies: AgeVerificationDependencies
    let ageLimit = 16
    var page: OnboardingPage
    var buttonAction: () -> () = {
    }
    var canGoToNextPage: Bool {
        dependencies.localStorage.dateOfBirth != nil
    }

    lazy var pageViewController = OnboardingPageViewController(buttonAction: buttonAction)

    lazy var ageVerificationField: AgeVerificationField = {
        let ageVerificationField = AgeVerificationField()
        ageVerificationField.registerAge = { [weak self] in
            self?.registerAgeButtonTapped()
        }

        ageVerificationField.backgroundColor = .appDarkViewBackground
        ageVerificationField.textColor = .appMainText
        ageVerificationField.datePicker.addTarget(self, action: #selector(self.datePickerValueChanged), for: .valueChanged)

        // Set date if available
        ageVerificationField.text = dependencies.localStorage.dateOfBirth?.stringValue
        ageVerificationField.placeholder = "dd.mm.yyyy"

        return ageVerificationField
    }()

    lazy var ageVerificationButton: AgeVerificationButton = {
        let button = AgeVerificationButton()
        button.addTarget(self, action: #selector(ageVerificationButtonTapped), for: .touchUpInside)
        return button
    }()

    @objc private func ageVerificationButtonTapped() {
        presentAgeVerificationExplanationAlert()
    }

    init(dependencies: AgeVerificationDependencies, page: OnboardingPage, buttonAction: @escaping () -> ()) {
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

    func render() {
        let stackView = pageViewController.stackView

        page.items.forEach {
            let view = $0.view
            stackView.addArrangedSubview(view)
        }

        [
            ageVerificationButton,
            ageVerificationField,
        ].forEach(stackView.addArrangedSubview(_:))

        let height: CGFloat = 56
        let horizontalMargin: CGFloat = DeviceTraitsService.shared.isSmall ? 20 : 40

        NSLayoutConstraint.activate([
            ageVerificationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalMargin),
            ageVerificationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalMargin),

            ageVerificationField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalMargin),
            ageVerificationField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalMargin),
            ageVerificationField.heightAnchor.constraint(greaterThanOrEqualToConstant: height),
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: nil) { [weak self] _ in
            self?.updateAgeVerificationButtonText()
        }
    }

    private func updateAgeVerificationButtonText() {
        ageVerificationButton.setTitle()
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            view.frame.origin.y = 0 - keyboardSize.height
        }
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
        view.frame.origin.y = 0
    }

    @objc func registerAgeButtonTapped() {
        ageVerificationField.resignFirstResponder()
        let selectedDate = ageVerificationField.datePicker.date

        guard let difference = Date().years(sinceDate: selectedDate), difference >= ageLimit else {
            presentAgeVerificationInvalidAgeAlert()
            dependencies.localStorage.dateOfBirth = nil
            pageViewController.button.isEnabled = false
            Logger.warning("Failed to validate age", tag: .onboardingAgeVerification)
            return
        }
        dependencies.localStorage.dateOfBirth = YearMonthDay(selectedDate)
        pageViewController.button.isEnabled = true
        Logger.info("Age was successfully validated", tag: .onboardingAgeVerification)
    }

    @objc func datePickerValueChanged(_ datePicker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        ageVerificationField.text = dateFormatter.string(from: datePicker.date)
    }
}
