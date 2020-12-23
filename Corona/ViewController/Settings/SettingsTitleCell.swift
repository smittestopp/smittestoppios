import UIKit

class SettingsTitleCell: UITableViewCell, WithReuseIdentifier {
    var versionString: String? {
        get {
            return appVersionLabel.text
        }
        set {
            appVersionLabel.text = newValue
            if let version = newValue {
                appVersionLabel.accessibilityLabel = "\("Settings.AppVersion".localized) \(version)"
            }
        }
    }

    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .custom(.bold, size: 34, forTextStyle: .title1)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.textColor = .appMainText
        label.text = "Settings.Title".localized
        label.isAccessibilityElement = true
        label.accessibilityIdentifier = "settingsTitle"
        return label
    }()

    lazy var appVersionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .custom(.medium, size: 12, forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .appMainText
        label.isAccessibilityElement = true
        label.accessibilityIdentifier = "settingsAppVersion"
        return label
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
            label,
            appVersionLabel,
            separatorView,
        ].forEach(contentView.addSubview(_:))

        let topMargin: CGFloat = DeviceTraitsService.shared.isSmall ? 10 : 40
        let bottomMargin: CGFloat = DeviceTraitsService.shared.isSmall ? 10 : 40

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topMargin),

            appVersionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            appVersionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            appVersionLabel.topAnchor.constraint(equalTo: label.bottomAnchor),
            appVersionLabel.bottomAnchor.constraint(equalTo: separatorView.topAnchor, constant: -bottomMargin),

            separatorView.heightAnchor.constraint(equalToConstant: 1),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}
