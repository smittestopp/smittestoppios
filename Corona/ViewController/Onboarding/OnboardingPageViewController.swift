import UIKit

typealias ButtonActionBlock = ((OnboardingButtonAction) -> Void)

class GradientView: UIView {
    var colors: [UIColor] = [] {
        didSet {
            gradientLayer.colors = colors.map(\.cgColor)
        }
    }

    var locations: [Double] = [] {
        didSet {
            gradientLayer.locations = locations.map { NSNumber(value: $0) }
        }
    }

    var startPoint: CGPoint = .zero {
        didSet {
            gradientLayer.startPoint = startPoint
        }
    }

    var endPoint: CGPoint = .zero {
        didSet {
            gradientLayer.endPoint = endPoint
        }
    }

    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
}

class OnboardingPageViewController: UIViewController {

    var buttonAction: (() -> ()) = {  }

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.alignment = .center
        view.distribution = .fill
        return view
    }()

    lazy var gradientView: GradientView = {
        let view = GradientView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.startPoint = CGPoint(x: 0.5, y: 0)
        view.endPoint = CGPoint(x: 0.5, y: 1)
        view.locations = [
            0.0,
            0.3,
        ]
        view.colors = [
            .init(white: 1, alpha: 0),
            .init(white: 1, alpha: 1),
        ]
        return view
    }()

    var button: MultilineButton = {
        let view = MultilineButton()
        view.translatesAutoresizingMaskIntoConstraints = false

        view.layer.cornerRadius = 8
        view.clipsToBounds = true

        view.setBackgroundColor(UIColor(red: 0.196, green: 0.204, blue: 0.361, alpha: 1), for: .normal)
        view.setBackgroundColor(UIColor(red: 0.196, green: 0.204, blue: 0.361, alpha: 0.5), for: .disabled)

        view.titleLabel?.font = .custom(.medium, size: 16, forTextStyle: .body)
        view.contentEdgeInsets = UIEdgeInsets(top: 9, left: 9, bottom: 9, right: 9)

        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true

        view.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        return view
    }()

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(buttonAction: @escaping (() -> ())) {
        self.buttonAction = buttonAction
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let margin = view.layoutMarginsGuide

        [
            scrollView,
            gradientView,
            button,
        ].forEach(view.addSubview(_:))

        scrollView.addSubview(stackView)

        let topMargin: CGFloat = DeviceTraitsService.shared.isSmall ? 4 : 20
        let horizontalMargin: CGFloat = DeviceTraitsService.shared.isSmall ? 20 : 40
        let buttonBottomMargin: CGFloat = DeviceTraitsService.shared.hasNotch ? 20 : 30
        let scrollBottomExtraMargin: CGFloat = DeviceTraitsService.shared.isSmall ? 20 : 40

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topMargin),
            scrollView.bottomAnchor.constraint(equalTo: button.topAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: horizontalMargin),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -horizontalMargin),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -horizontalMargin * 2),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -scrollBottomExtraMargin),

            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.topAnchor.constraint(equalTo: button.topAnchor, constant: -20),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalMargin),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalMargin),
            button.bottomAnchor.constraint(equalTo: margin.bottomAnchor, constant: -buttonBottomMargin),
        ])
    }

    @objc func buttonTapped() {
        buttonAction()
    }
}
