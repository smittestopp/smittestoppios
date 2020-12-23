import UIKit

class SettingsPrivacyPolicyViewController: PrivacyPolicyViewController {

    private var privacyPolicyHTML: String

    lazy var gradientView: GradientView = {
        let view = GradientView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.startPoint = CGPoint(x: 0.5, y: 0)
        view.endPoint = CGPoint(x: 0.5, y: 1)
        view.locations = [
            0.0,
            0.3,
        ]
        view.colors = [
            .init(white: 1, alpha: 0),
            .init(white: 1, alpha: 1),
        ]
        return view
    }()

    lazy var closeButton: PrivacyPolicyButton = {
        let closeButton = PrivacyPolicyButton()
        closeButton.backgroundColor = UIColor(red: 0.196, green: 0.204, blue: 0.361, alpha: 1)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.setTitle("CloseButton.Title".localized.uppercased(), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.accessibilityIdentifier = "closePrivacyButton"
        return closeButton
    }()

    init(privacyPolicyHTML: String) {
        self.privacyPolicyHTML = privacyPolicyHTML

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
        [
            scrollView,
            gradientView,
            closeButton,
        ].forEach(view.addSubview(_:))

        scrollView.addSubview(stackView)

        [
            titleLabel,
            textView,
        ].forEach(stackView.addArrangedSubview(_:))

        let margin = view.layoutMarginsGuide

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scrollView.bottomAnchor.constraint(equalTo: closeButton.topAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: horizontalMargin),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -horizontalMargin),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -horizontalMargin * 2),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.topAnchor.constraint(equalTo: closeButton.topAnchor, constant: -30),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalMargin),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalMargin),
            closeButton.bottomAnchor.constraint(equalTo: margin.bottomAnchor, constant: -buttonBottomMargin),
        ])

        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: nil) { [weak self] _ in
            self?.renderText()
        }
    }

    @objc func closeButtonTapped(_: Any) {
        dismiss(animated: true, completion: nil)
    }

    private func renderText() {
        textView.attributedText = privacyPolicyAttributedString(privacyPolicyHTML)
    }
}
