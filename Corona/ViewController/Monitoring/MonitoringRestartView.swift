import UIKit

class MonitoringRestartView: UIView {
    var restartButtonTapped: (()->Void)?

    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = 60
        return view
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = .custom(.bold, size: 18, forTextStyle: .body)
        label.textAlignment = .center
        label.textColor = .appMainText
        label.text = "Monitoring.RestartMonitoring.Description".localized
        label.numberOfLines = 0
        label.accessibilityIdentifier = "monitoringDeactivatedText"
        return label
    }()

    lazy var shareButton: MonitoringStandardButton = {
        let button = MonitoringStandardButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Monitoring.RestartMonitoring.Button.Title".localized, for: .normal)
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        button.accessibilityIdentifier = "monitoringRestartButton"
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
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30),
        ])
    }

    @objc private func tapped() {
        restartButtonTapped?()
    }
}
