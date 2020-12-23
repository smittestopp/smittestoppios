import UIKit

class AgeVerificationButton: MultilineButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func setup() {
        super.setup()
        setTitle()
        translatesAutoresizingMaskIntoConstraints = false
        accessibilityIdentifier = "ageVerificationExplanationButton"
        heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
    }

    func setTitle(){
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.custom(.regular, size: 16, forTextStyle: .body),
            .foregroundColor: UIColor.appMainText,
            .underlineStyle: NSUnderlineStyle.single.rawValue]

        let title = NSMutableAttributedString(string: "AgeVerification.Explanation.Description".localized, attributes: attributes)
        setAttributedTitle(title, for: .normal)
    }
}
