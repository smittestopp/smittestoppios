import UIKit

class OnboardingPageRendererViewController: UIViewController, OnboardingPagePresenter {

    var page: OnboardingPage

    var buttonAction: ButtonActionBlock = { _ in }

    lazy var pageViewController = OnboardingPageViewController(buttonAction: { [weak self] in
        guard let action = self?.page.buttonAction else {
            return
        }

        self?.buttonAction(action)
    })

    init(_ page: OnboardingPage, buttonAction: @escaping ButtonActionBlock) {
        self.page = page
        self.buttonAction = buttonAction

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        install(pageViewController)

        renderPage()

        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: nil) { [weak self] _ in
                self?.updateContentForContentSizeCategory()
        }

    }

    func renderPage() {
        pageViewController.stackView.removeAllArrangedSubviews()

        page.items.forEach {
            let view = $0.view
            pageViewController.stackView.addArrangedSubview(view)
        }

        pageViewController.button.setTitle(page.buttonText, for: .normal)
        pageViewController.button.accessibilityIdentifier = page.buttonIdentifier
    }

    private func updateContentForContentSizeCategory() {
        renderPage()
    }
}

extension OnboardingPageItemElement {
    var view: UIView {
        switch self {

        case .spacer(let size):
            let view = UIView()
            view.heightAnchor.constraint(equalToConstant: CGFloat(size)).isActive = true
            return view
        case .label(let text, let size, let bold, let identifier):
            let label = UILabel()
            label.text = text
            label.font = .custom(bold ? .bold : .regular, size: size, forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = .appMainText
            label.accessibilityIdentifier = identifier
            return label
        case .localImage(let named):
            let imageView = UIImageView(image: UIImage(named: named))
            imageView.sizeToFit()
            return imageView
        case .image:
            return UIImageView()
        }
    }
}
