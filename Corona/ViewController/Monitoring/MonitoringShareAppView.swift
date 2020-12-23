import UIKit

class MonitoringShareAppView: UIView {
    var shareButtonTapped: (()->Void)?

    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = DeviceTraitsService.shared.isSmall ? 8 : 20
        return view
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = .custom(.bold, size: 16, forTextStyle: .footnote)
        label.textAlignment = .center
        label.textColor = .appMainText
        label.text = "Monitoring.ShareApp.Button.Description".localized
        label.accessibilityIdentifier = "monitoringShareTitle"
        return label
    }()

    lazy var shareButton: MonitoringStandardButton = {
        let button = MonitoringStandardButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Monitoring.ShareApp.Button.Title".localized, for: .normal)
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        button.accessibilityIdentifier = "monitoringShareButton"
        return button
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
            label,
            shareButton,
        ].forEach(stackView.addArrangedSubview(_:))

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 30),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30),
        ])
    }

    @objc private func tapped() {
        shareButtonTapped?()
    }
}
