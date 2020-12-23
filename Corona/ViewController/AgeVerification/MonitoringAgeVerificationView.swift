import UIKit

class MonitoringAgeVerificationView: UIView {

    var registerAgeButtonTapped: (() -> Void)?
    var explanationButtonTapped: (() -> Void)?

    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = DeviceTraitsService.shared.isSmall ? 4 : 10
        return view
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = .custom(.bold, size: 18, forTextStyle: .footnote)
        label.textAlignment = .center
        label.textColor = .appMainText
        label.text = "Monitoring.AgeVerification.Button.Description".localized
        label.accessibilityIdentifier = "monitoringRegisterAgeDescription"
        return label
    }()

    lazy var ageVerificationField: AgeVerificationField = {
        let ageVerificationField = AgeVerificationField()
        ageVerificationField.registerAge = { [weak self] in
            self?.registerAgeButtonTapped?()
        }
        ageVerificationField.text = "Monitoring.AgeVerification.Button.Title".localized
        ageVerificationField.backgroundColor = .appDeleteDataButtonBackground
        ageVerificationField.textColor = .appDeleteDataButtonText
        ageVerificationField.tintColor = .clear
        ageVerificationField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return ageVerificationField
    }()

    lazy var ageVerificationButton: AgeVerificationButton = {
        let button = AgeVerificationButton()
        button.addTarget(self, action: #selector(ageVerificationButtonTapped), for: .touchUpInside)
        return button
    }()

    @objc private func ageVerificationButtonTapped() {
        explanationButtonTapped?()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(stackView)
        [
            label,
            ageVerificationButton,
            ageVerificationField,
        ].forEach(stackView.addArrangedSubview(_:))

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30),
        ])
    }
}
