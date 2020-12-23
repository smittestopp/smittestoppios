import UIKit

class SettingsAuthorizationsCell: UITableViewCell, WithReuseIdentifier {
    var monitoringToggled: ((Bool)->Void)?

    var isOn: Bool = false {
        didSet{
            monitoringSwitch.isOn = isOn
            if isOn {
                monitoringSwitch.setTitle("Settings.Authorization.Monitoring.OnTitle".localized)
                monitoringSwitch.accessibilityLabel = "Settings.Authorization.Monitoring.OnAccessibilityLabel".localized
            } else {
                monitoringSwitch.setTitle("Settings.Authorization.Monitoring.OffTitle".localized)
                monitoringSwitch.accessibilityLabel = "Settings.Authorization.Monitoring.OffAccessibilityLabel".localized
            }
        }
    }

    lazy var stackView: UIStackView = {
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
        label.text = "Settings.Authorizations.Title".localized
        label.isAccessibilityElement = true
        label.accessibilityIdentifier = "settingsMonitoringTitle"
        return label
    }()

    lazy var monitoringSwitch: SwitchWithLabel = {
        let monitoringSwitch = SwitchWithLabel()
        monitoringSwitch.translatesAutoresizingMaskIntoConstraints = false
        monitoringSwitch.titleFont = .custom(.medium, size: 14, forTextStyle: .body)
        monitoringSwitch.titleTextColor = .appMainText
        monitoringSwitch.onTintColor = UIColor(red: 0.02, green: 0.502, blue: 0.655, alpha: 1)
        monitoringSwitch.switchToggled = { [weak self] isOn in
            self?.monitoringToggled?(isOn)
        }
        monitoringSwitch.accessibilityIdentifier = "settingsMonitoringSwitch"
        return monitoringSwitch
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
            monitoringSwitch,
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
    }
}
