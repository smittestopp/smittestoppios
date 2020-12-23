import UIKit

fileprivate extension String {
    static let info = "InfoVC"
}

class InfoViewController: UIViewController {
    static func instantiate() -> UIViewController {
        let vc = InfoViewController()
        vc.tabBarItem = UITabBarItem(title: "Tab.Info".localized, image: UIImage(named: "tab-info"), tag: 0)
        vc.tabBarItem.accessibilityIdentifier = "infoTab"
        return vc
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

    lazy var labelsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    let headerView = InfoHeaderView()

    struct Link {
        let title: String
        let url: String
        let identifier: String
    }

    enum Label {
        case link(Link)
        case text(String)
    }

    private let labels: [Label] = [
        .link(.init(title: "Info.Link.Information".localized, url: "https://helsenorge.no/koronavirus", identifier: "infoLinkInformation")),
        .link(.init(title: "Info.Link.Smittestopp".localized, url: "https://helsenorge.no/smittestopp", identifier: "infoLinkSmittestopp")),
        .text("Info.Text.DigitalTools".localized),
        .link(.init(title: "Info.Link.StoredData".localized, url: "https://helsenorge.no/koronavirus/koronaverktoy", identifier: "infoLinkTools")),
        .link(.init(title: "Info.Link.SelfReport".localized, url: "https://helsenorge.no/koronavirus/koronasmitte", identifier: "infoLinkSelfReport")),
    ]

    init() {
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        view.backgroundColor = .appViewBackground
        view.accessibilityIdentifier = "infoView"

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        let horizontalMargin: CGFloat = 40

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: horizontalMargin),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -horizontalMargin),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -horizontalMargin * 2),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ])

        [
            headerView,
            labelsStackView,
        ].forEach(stackView.addArrangedSubview(_:))

        stackView.setCustomSpacing(40, after: headerView)

        setupLinks()

        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: nil) { [weak self] _ in
            self?.setupLinks()
        }
    }

    private func setupLinks() {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.custom(.regular, size: 18, forTextStyle: .body),
            .foregroundColor: UIColor.appMainText,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .paragraphStyle: NSMutableParagraphStyle()
                .with(lineHeight: 25)
                .with(alignment: .center),
        ]

        let buttons = labels.enumerated().map { (index, label) -> UIView in
            switch label {
            case let .link(link):
                let title = NSAttributedString(string: link.title, attributes: titleAttributes)
                let button = MultilineButton()
                button.setAttributedTitle(title, for: .normal)
                button.tag = index
                button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
                button.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
                button.accessibilityIdentifier = link.identifier
                return button
            case let .text(text):
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.adjustsFontForContentSizeCategory = true
                label.numberOfLines = 0
                label.font = .custom(.medium, size: 18, forTextStyle: .body)
                label.textAlignment = .center
                label.textColor = .appMainText
                label.text = text
                return label
            }
        }

        labelsStackView.removeAllArrangedSubviews()
        buttons.forEach(labelsStackView.addArrangedSubview(_:))
    }

    @objc private func tapped(_ sender: UIButton) {
        let index = sender.tag

        guard index >= 0 && index < labels.count else {
            assertionFailure()
            return
        }

        guard case let .link(link) = labels[index] else {
            assertionFailure()
            return
        }

        let urlString = link.url
        open(urlString)
    }

    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            Logger.warning("Failed to make url: \"\(urlString)\"", tag: .info)
            return
        }

        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                Logger.warning("Failed to open url: \"\(urlString)\"", tag: .info)
            }
        }
    }
}
