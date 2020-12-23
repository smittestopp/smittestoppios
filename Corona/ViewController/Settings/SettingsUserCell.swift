import UIKit

class SettingsUserCell: UITableViewCell, WithReuseIdentifier {
    var privacyTapped: (() -> Void)?
    var phoneNumber: String? {
        get {
            return phoneNumberLabel.text
        }
        set {
            phoneNumberLabel.text = newValue
        }
    }

    var logoutButtonTapped: (()->Void)?
    var secretTapped: (()->Void)?

    lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let isVertical = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        if isVertical {
            stackView.axis = .vertical
            stackView.distribution = .fill
            stackView.alignment = .fill
        } else {
            stackView.axis = .horizontal
            stackView.distribution = .fill
            stackView.alignment = .center
        }

        stackView.spacing = 8

        return stackView
    }()

    lazy var titleAndPhoneNumberStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .custom(.medium, size: 24, forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .appMainText
        label.text = "Settings.User.Title".localized
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.isAccessibilityElement = true
        label.accessibilityIdentifier = "settingsUserTitle"
        return label
    }()

    lazy var phoneNumberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .custom(.medium, size: 14, forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .appMainText
        label.text = "+47 00000000"
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.isAccessibilityElement = true
        label.accessibilityIdentifier = "settingsUserPhoneNumber"
        return label
    }()

    lazy var logoutButton: MultilineButton = {
        let button = MultilineButton()
        button.translatesAutoresizingMaskIntoConstraints = false

        button.titleLabel?.font = .custom(.medium, size: 14, forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitleColor(.appSupportScreenText, for: .normal)
        button.setTitle("Settings.User.LogoutButton.Title".localized, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 9, left: 16, bottom: 9, right: 16)

        button.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)

        button.layer.borderColor = UIColor.appSupportScreenText.cgColor
        button.layer.borderWidth = 2
        button.layer.cornerRadius = 2

        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        button.accessibilityIdentifier = "settingsLogoutButton"
        return button
    }()

    lazy var privacyButton: MultilineButton = {
        let button = MultilineButton()
        button.translatesAutoresizingMaskIntoConstraints = false

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.custom(.medium, size: 14, forTextStyle: .body),
            .foregroundColor: UIColor.appMainText,
            .underlineStyle: NSUnderlineStyle.single.rawValue]

        let title = NSMutableAttributedString(string: "PrivacyPolicy.Title".localized, attributes: attributes)
        button.setAttributedTitle(title, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 13, left: 0, bottom: 13, right: 0)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(policyTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "settingsPrivacyButton"
        return button
    }()

    lazy var separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .appSeparator
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear

        [
            mainStackView,
            separatorView,
        ].forEach(contentView.addSubview(_:))

        [
            titleAndPhoneNumberStackView,
            logoutButton,
        ].forEach(mainStackView.addArrangedSubview(_:))

        [
            titleLabel,
            phoneNumberLabel,
            privacyButton,
        ].forEach(titleAndPhoneNumberStackView.addArrangedSubview)

        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStackView.bottomAnchor.constraint(equalTo: separatorView.topAnchor, constant: -16),

            separatorView.heightAnchor.constraint(equalToConstant: 1),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        // Setup secret tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(secretTap))
        tap.numberOfTapsRequired = 5
        contentView.addGestureRecognizer(tap)
    }

    @objc private func secretTap() {
        secretTapped?()
    }

    @objc private func logoutTapped() {
        logoutButtonTapped?()
    }

    @objc private func policyTapped() {
        privacyTapped?()
    }
}
