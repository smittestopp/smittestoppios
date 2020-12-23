import UIKit

class PrivacyPolicyViewController: UIViewController {

    let topMargin: CGFloat = DeviceTraitsService.shared.isSmall ? 4 : 20
    let horizontalMargin: CGFloat = DeviceTraitsService.shared.isSmall ? 10 : 20
    let buttonBottomMargin: CGFloat = DeviceTraitsService.shared.hasNotch ? 10 : 20
    let scrollBottomExtraMargin: CGFloat = DeviceTraitsService.shared.isSmall ? 20 : 40

    func privacyPolicyAttributedString(_ privacyPolicyHTML: String) -> NSAttributedString {
        let stylesheet = NSMutableAttributedString.Stylesheet(styles: [
            .init(element: "*", attributes: [
                .fontWeight(.regular),
                .fontSize(UIFont.scaledSize(15, forTextStyle: .body)),
                .textColor(.appMainText),
            ]),
            .init(element: "h1", attributes: [
                .fontWeight(.bold),
                .fontSize(UIFont.scaledSize(16, forTextStyle: .title1)),
            ]),
            .init(element: "h2", attributes: [
                .fontWeight(.bold),
                .fontSize(UIFont.scaledSize(15, forTextStyle: .title2)),
            ]),
            .init(element: "h3", attributes: [
                .fontWeight(.bold),
                .fontSize(UIFont.scaledSize(15, forTextStyle: .title3)),
            ]),
            .init(element: "b", attributes: [
                .fontWeight(.bold),
            ]),
            .init(element: "i", attributes: [
                .fontWeight(.regularItalic),
            ]),
        ])

        return NSMutableAttributedString.fromHTML(privacyPolicyHTML, style: stylesheet)
    }

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.font = .custom(.bold, size: 34, forTextStyle: .title1)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .appMainText
        titleLabel.text = "PrivacyPolicy.Title".localized
        titleLabel.accessibilityIdentifier = "privacyPolicyTitle"
        return titleLabel
    }()

    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.adjustsFontForContentSizeCategory = true
        textView.backgroundColor = .appViewBackground
        textView.textAlignment = .left
        textView.isEditable = false
        textView.isScrollEnabled = false
        return textView
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .appViewBackground
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
