import UIKit

class MonitoringHeaderView: UIView {
    enum State {
        /// All good
        case working
        /// Either GPS or Bluetooth is working
        case partiallyWorking
        /// Both GPS and Bluetooth do not have enough authorizations
        case notWorking
        /// Monitoring deactivated by user in our app settings page
        case deactivated
    }

    var state: State = .working {
        didSet {
            stateChanged()
        }
    }

    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = DeviceTraitsService.shared.isSmall ? 10 : 20
        return view
    }()

    lazy var topSpacerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = .appMonitoringEnabledImage
        imageView.isAccessibilityElement = true
        imageView.accessibilityIdentifier = "monitoringImage"
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = .custom(.bold, size: 34, forTextStyle: .title1)
        label.textAlignment = .center
        label.textColor = .appMainText
        label.text = "Monitoring.Title".localized
        label.accessibilityIdentifier = "monitoringTitle"
        return label
    }()

    lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = .custom(.bold, size: 18, forTextStyle: .body)
        label.textAlignment = .center
        label.accessibilityIdentifier = "monitoringStatus"
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        [
            topSpacerView,
            titleLabel,
            imageView,
            statusLabel,
        ].forEach(stackView.addArrangedSubview(_:))

        stackView.setCustomSpacing(12, after: imageView)

        addSubview(stackView)

        let topMargin: CGFloat = DeviceTraitsService.shared.isSmall ? 10 : 40

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            topSpacerView.heightAnchor.constraint(equalToConstant: topMargin),
        ])
    }

    private func stateChanged() {
        switch state {
        case .working:
            imageView.image = .appMonitoringEnabledImage
            statusLabel.text = "Monitoring.Header.FullyActivated".localized
            statusLabel.textColor = .appMonitoringActivatedText
        case .partiallyWorking:
            imageView.image = .appMonitoringPartiallyEnabledImage
            statusLabel.text = "Monitoring.Header.PartiallyActivated".localized
            statusLabel.textColor = .appMonitoringPartiallyActivatedText
        case .notWorking:
            imageView.image = .appMonitoringDisabledImage
            statusLabel.text = "Monitoring.Header.NotWorking".localized
            statusLabel.textColor = .appMonitoringPartiallyActivatedText
        case .deactivated:
            imageView.image = .appMonitoringDisabledImage
            statusLabel.text = "Monitoring.Header.Deactivated".localized
            statusLabel.textColor = .appMonitoringDeactivatedText
        }
    }
}
