import UIKit

class PermissionItemView: UIView {
    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    var text: String? {
        get {
            return textLabel.text
        }
        set {
            textLabel.text = newValue
        }
    }

    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
        }
    }

    var buttonAction: ((PermissionActionButton) -> ())?

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = .custom(.bold, size: 22, forTextStyle: .headline)
        label.textColor = .appMainText
        return label
    }()

    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = .custom(.regular, size: 17, forTextStyle: .body)
        label.textColor = .appMainText
        return label
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var button: PermissionActionButton = {
        let button = PermissionActionButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(tappedButton), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        [
            imageView,
            titleLabel,
            textLabel,
            button,
        ].forEach(addSubview(_:))

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 70),
            imageView.heightAnchor.constraint(equalToConstant: 70),

            titleLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: imageView.trailingAnchor, multiplier: 1),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),

            textLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            textLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            textLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),

            button.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            button.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 14),
            button.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])
    }

    @objc func tappedButton(sender: PermissionActionButton) {
        buttonAction?(sender)
    }
}
