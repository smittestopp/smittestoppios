import UIKit

class SettingsNotificationCell: UITableViewCell, WithReuseIdentifier {
    var showValidationCodeTapped: (() -> Void)?

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    lazy var separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .appSeparator
        return view
    }()

    lazy var pinCodeStackView: UIStackView = {
        let pinCodeStackView = UIStackView()
        pinCodeStackView.translatesAutoresizingMaskIntoConstraints = false
        pinCodeStackView.axis = .vertical
        pinCodeStackView.spacing = 12
        return pinCodeStackView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .custom(.medium, size: 24, forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .appMainText
        label.text = "Settings.Notifications.Title".localized
        label.isAccessibilityElement = true
        label.accessibilityIdentifier = "settingsNotificationsTitle"
        return label
    }()

    lazy var retrievePinCodesButton: MonitoringStandardButton = {
        let button = MonitoringStandardButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Settings.Notifications.Button.Title".localized, for: .normal)
        button.addTarget(self, action: #selector(retrievePinCodesButtonTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "settingsNotificationButton"
        return button
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
            stackView,
            separatorView,
        ].forEach(contentView.addSubview(_:))

        [
            titleLabel,
            retrievePinCodesButton,
            pinCodeStackView,
        ].forEach(stackView.addArrangedSubview)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: separatorView.topAnchor, constant: -26),

            separatorView.heightAnchor.constraint(equalToConstant: 1),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    @objc private func retrievePinCodesButtonTapped() {
        showValidationCodeTapped?()
    }
}
