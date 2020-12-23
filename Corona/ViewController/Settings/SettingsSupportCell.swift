import UIKit

class SettingsSupportCell: UITableViewCell, WithReuseIdentifier {
    static var supportLink = "https://helsenorge.no/kontakt"
    static var supportPhoneNumber = "23 32 70 00"

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 6
        return stackView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .custom(.medium, size: 24, forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .appMainText
        label.text = "Settings.Support.Title".localized
        label.isAccessibilityElement = true
        label.accessibilityIdentifier = "settingsSupportTitle"
        return label
    }()

    lazy var phoneButton: MultilineButton = {
        let button = MultilineButton()
        button.translatesAutoresizingMaskIntoConstraints = false

        button.contentEdgeInsets = UIEdgeInsets(top: 13, left: 9, bottom: 13, right: 9)
        button.contentHorizontalAlignment = .left

        button.addTarget(self, action: #selector(phoneTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "settingsSupportPhoneNumber"
        return button
    }()

    lazy var linkButton: MultilineButton = {
        let button = MultilineButton()
        button.translatesAutoresizingMaskIntoConstraints = false

        button.contentEdgeInsets = UIEdgeInsets(top: 13, left: 9, bottom: 13, right: 9)
        button.contentHorizontalAlignment = .left

        button.addTarget(self, action: #selector(linkTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "settingsSupportLink"
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
            stackView,
            separatorView,
        ].forEach(contentView.addSubview(_:))

        [
            titleLabel,
            linkButton,
            phoneButton,
        ].forEach(stackView.addArrangedSubview)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: separatorView.topAnchor, constant: -16),

            separatorView.heightAnchor.constraint(equalToConstant: 1),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: nil) { [weak self] _ in
                self?.updateContentForContentSizeCategory()
        }

        updateContentForContentSizeCategory()
    }

    private func updatePhoneButtonText() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.custom(.regular, size: 14, forTextStyle: .body),
            .foregroundColor: UIColor.appSupportScreenText,
            .underlineStyle: NSUnderlineStyle.single.rawValue]

        let attributeString = NSMutableAttributedString(string: Self.supportPhoneNumber,
                                                        attributes: attributes)
        phoneButton.setAttributedTitle(attributeString, for: .normal)
        phoneButton.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    private func updateLinkText() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.custom(.regular, size: 14, forTextStyle: .body),
            .foregroundColor: UIColor.appSupportScreenText,
            .underlineStyle: NSUnderlineStyle.single.rawValue]

        let attributeString = NSMutableAttributedString(string: Self.supportLink,
                                                        attributes: attributes)
        linkButton.setAttributedTitle(attributeString, for: .normal)
        linkButton.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    private func updateContentForContentSizeCategory() {
        updatePhoneButtonText()
        updateLinkText()
    }

    @objc private func linkTapped() {
        UIApplication.shared.open(URL(string: Self.supportLink)!, options: [:]) { success in
            if !success {
                Logger.warning("Failed to open support url", tag: "Settings")
            }
        }
    }

    @objc private func phoneTapped() {
        guard let phoneNumber = phoneButton.attributedTitle(for: .normal)?.string else {
            Logger.warning("Failed to get phone number", tag: "Settings")
            return
        }

        let allowedCharacters = "+0123456789"
        let sanitizedPhoneNumber = phoneNumber.filter { allowedCharacters.contains($0) }

        guard let url = URL(string: "tel:\(sanitizedPhoneNumber)") else {
            Logger.warning("Failed to make url with phone number: \"\(phoneNumber)\"", tag: "Settings")
            return
        }

        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                Logger.warning("Failed to call: \"\(phoneNumber)\"", tag: "Settings")
            }
        }
    }
}
