import UIKit

class OnboardingPrivacyPolicyViewController: PrivacyPolicyViewController {
    var privacyPolicyHTML: String

    private var acceptBlock: () -> () = { }
    private var denyBlock: () -> () = { }

    lazy var denyButton: PrivacyPolicyButton = {
        let denyButton = PrivacyPolicyButton()
        denyButton.setTitle("PrivacyPolicy.DeclineButton.Title".localized.uppercased(), for: .normal)
        denyButton.addTarget(self, action: #selector(denyButtonTapped), for: .touchUpInside)
        denyButton.accessibilityIdentifier = "declinePrivacyButton"
        return denyButton
    }()

    lazy var acceptButton: PrivacyPolicyButton = {
        let acceptButton = PrivacyPolicyButton()
        acceptButton.backgroundColor = UIColor(red: 0.196, green: 0.204, blue: 0.361, alpha: 1)
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.setTitle("PrivacyPolicy.AcceptButton.Title".localized.uppercased(), for: .normal)
        acceptButton.addTarget(self, action: #selector(acceptButtonTapped), for: .touchUpInside)
        acceptButton.accessibilityIdentifier = "acceptPrivacyButton"
        return acceptButton
    }()

    lazy var buttonsStackView: UIStackView = {
        let buttonsStackView = UIStackView()
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.axis = .horizontal
        buttonsStackView.alignment = .fill
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.spacing = 20
        return buttonsStackView
    }()

    init(privacyPolicyHTML: String, acceptBlock: @escaping () -> (), denyBlock: @escaping () -> ()) {
        self.privacyPolicyHTML = privacyPolicyHTML
        self.denyBlock = denyBlock
        self.acceptBlock = acceptBlock

        super.init()
        setup()
    }

    required init?(coder: NSCoder) {
        privacyPolicyHTML = ""
        super.init(coder: coder)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        renderText()
    }

    private func setup() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        [
            titleLabel,
            textView,
            buttonsStackView,
        ].forEach(stackView.addArrangedSubview(_:))

        [
            denyButton,
            acceptButton,
        ].forEach(buttonsStackView.addArrangedSubview(_:))

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topMargin),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: horizontalMargin),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -horizontalMargin),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -horizontalMargin * 2),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -scrollBottomExtraMargin),
        ])

        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: nil) { [weak self] _ in
            self?.renderText()
        }
    }

    @objc func denyButtonTapped(_: Any) {
        denyBlock()
    }

    @objc func acceptButtonTapped(_: Any) {
        acceptBlock()
    }

    private func renderText() {
        textView.attributedText = privacyPolicyAttributedString(privacyPolicyHTML)
    }
}
