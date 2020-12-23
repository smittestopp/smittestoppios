import UIKit

class InfoHeaderView: UIView {
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = DeviceTraitsService.shared.isSmall ? 10 : 40
        return view
    }()

    lazy var topSpacerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = .custom(.bold, size: 34, forTextStyle: .title1)
        label.textAlignment = .center
        label.textColor = .appMainText
        label.text = "Info.Title".localized
        label.accessibilityIdentifier = "infoTitle"
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
        ].forEach(stackView.addArrangedSubview(_:))

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            topSpacerView.heightAnchor.constraint(equalToConstant: DeviceTraitsService.shared.isSmall ? 10 : 40),
        ])
    }
}
