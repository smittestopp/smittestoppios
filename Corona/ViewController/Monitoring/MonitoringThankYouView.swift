import UIKit

class MonitoringThankYouView: UIView {
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = 20
        return view
    }()

    lazy var thankYouLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = .custom(.bold, size: 24, forTextStyle: .callout)
        label.textAlignment = .center
        label.textColor = .appMainText
        label.text = "Monitoring.ThankYou.Title".localized
        label.numberOfLines = 0
        label.accessibilityIdentifier = "monitoringActivatedTitle"
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.custom(.regular, size: 18, forTextStyle: .body),
            .foregroundColor: UIColor.appMainText,
            .paragraphStyle: NSMutableParagraphStyle()
                .with(lineHeight: 25)
                .with(alignment: .center),
        ]

        label.attributedText = NSAttributedString(
            string: "Monitoring.ThankYou.Description".localized,
            attributes: attributes)
        label.accessibilityIdentifier = "monitoringActivatedText"

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
            thankYouLabel,
            descriptionLabel,
        ].forEach(stackView.addArrangedSubview(_:))

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
