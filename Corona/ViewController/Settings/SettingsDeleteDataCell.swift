import UIKit

class SettingsDeleteDataCell: UITableViewCell, WithReuseIdentifier {
    var secretTapActivated: (()->Void)?
    var deleteButtonTapped: (()->Void)?

    lazy var deleteDataButton: MultilineButton = {
        let button = MultilineButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(.solid(.appDeleteDataButtonBackground), for: .normal)
        button.setBackgroundImage(.solid(.red), for: .highlighted)
        button.setTitleColor(.appDeleteDataButtonText, for: .normal)
        button.setTitle("Settings.DeleteAllMyDataButton.Title".localized, for: .normal)
        button.titleLabel?.font = .custom(.regular, size: 14, forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentEdgeInsets = UIEdgeInsets(top: 13, left: 9, bottom: 13, right: 9)
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        button.accessibilityIdentifier = "settingsDeleteDataButton"

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
            deleteDataButton,
        ].forEach(contentView.addSubview(_:))

        NSLayoutConstraint.activate([
            deleteDataButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 50),
            deleteDataButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -50),
            deleteDataButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 50),
            deleteDataButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50),
        ])

        // Setup secret tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(secretTap))
        tap.numberOfTapsRequired = 5
        contentView.addGestureRecognizer(tap)
    }

    @objc private func tapped() {
        deleteButtonTapped?()
    }

    @objc private func secretTap() {
        secretTapActivated?()
    }
}
