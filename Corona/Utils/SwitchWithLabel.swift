import UIKit

/// A UISwitch with a text label.
/// The main difference between using just plain UISwitch+UILabel and this - added accessibility support.
class SwitchWithLabel: UIView {
    enum State {
        case on
        case off
    }

    var state: State = .off {
        didSet {
            switchButton.isOn = state == .on
        }
    }

    var isOn: Bool {
        get {
            return switchButton.isOn
        }
        set {
            switchButton.isOn = newValue
        }
    }

    /// Callback when the switch is tapped.
    var switchToggled: ((Bool)->Void)?

    var onTintColor: UIColor? {
        get {
            return switchButton.onTintColor
        }
        set {
            switchButton.onTintColor = newValue
        }
    }

    var titleFont: UIFont {
        get {
            return textLabel.font
        }
        set {
            textLabel.font = newValue
            textLabel.adjustsFontForContentSizeCategory = true
        }
    }

    var titleTextColor: UIColor {
        get {
            return textLabel.textColor
        }
        set {
            textLabel.textColor = newValue
        }
    }

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 15
        [
            switchButton,
            textLabel,
        ].forEach(stackView.addArrangedSubview(_:))
        return stackView
    }()

    private lazy var switchButton: UISwitch = {
        let button = UISwitch()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        button.onTintColor = UIColor(red: 0.02, green: 0.502, blue: 0.655, alpha: 1)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    override var accessibilityValue: String? {
        get {
            // For VoiceOver to announce "on" and "off" this value should be "1" and "0"
            return isOn ? "1" : "0"
        }
        set { }
    }

    /// Set a text next to the switch to a given `title` value in a given `state`.
    func setTitle(_ title: String) {
        textLabel.text = title
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        accessibilityElements = [switchButton, textLabel]
        isAccessibilityElement = true
        accessibilityTraits = switchButton.accessibilityTraits

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapped))
        addGestureRecognizer(tapGesture)
    }

    @objc private func valueChanged() {
        switchToggled?(isOn)
    }

    @objc private func handleTapped() {
        switchButton.setOn(!isOn, animated: true)
        switchButton.sendActions(for: .valueChanged)
    }

    override func accessibilityActivate() -> Bool {
        switchButton.setOn(!switchButton.isOn, animated: false)
        switchButton.sendActions(for: .valueChanged)
        return true
    }
}
