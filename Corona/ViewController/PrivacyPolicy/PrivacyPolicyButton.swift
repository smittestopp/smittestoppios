import UIKit

class PrivacyPolicyButton: MultilineButton {
    private let color = UIColor(red: 0.196, green: 0.204, blue: 0.361, alpha: 1)
    private let edgeInsets = UIEdgeInsets(top: 9, left: 9, bottom: 9, right: 9)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        contentEdgeInsets = edgeInsets
        layer.borderColor = color.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 8
        setTitleColor(color, for: .normal)
        titleLabel?.font = .custom(.regular, size: 18, forTextStyle: .body)
        heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }
}
