import UIKit

/// A button that allows its title to occupy multiple lines.
class MultilineButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override var intrinsicContentSize: CGSize {
        let horizontalInsets = contentEdgeInsets.left + contentEdgeInsets.right
        let verticalInsets = contentEdgeInsets.top + contentEdgeInsets.bottom

        guard let contentSize = titleLabel?.intrinsicContentSize else {
            return super.intrinsicContentSize
        }

        return CGSize(width: contentSize.width + horizontalInsets, height: contentSize.height + verticalInsets)
    }

    func setup() {
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.textAlignment = .center
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let titleLabel = self.titleLabel else { return }
        titleLabel.preferredMaxLayoutWidth = titleLabel.frame.size.width
        super.layoutSubviews()
    }
}
