import UIKit
// Inspired by https://github.com/ivanvorobei/SPPermissions/blob/master/Source/SPPermissions/Interface/Shared/Buttons/SPPermissionActionButton.swift
class PermissionActionButton: UIButton {
    /**
     Title of button when permission not authorized yet.
     */
    public var allowTitle: String? { didSet { applyStyle() } }

    /**
     Title of button when permission authorized.
     */
    public var allowedTitle: String? { didSet { applyStyle() } }

    /**
     Title color for button when permissin not authorized yet.
     */
    public var allowTitleColor: UIColor = #colorLiteral(red: 0.2235294118, green: 0.2352941176, blue: 0.3803921569, alpha: 1) { didSet { applyStyle() } }

    /**
     Background button color when permissin not authorized yet.
     */
    public var allowBackgroundColor: UIColor = #colorLiteral(red: 0.8135123849, green: 0.8684031367, blue: 0.8931450248, alpha: 1) { didSet { applyStyle() } }

    /**
     Title color for button when permissin authorized.
     */
    public var allowedTitleColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) { didSet { applyStyle() } }

    /**
     Background button color when permission authorized.
     */
    public var allowedBackgroundColor: UIColor = #colorLiteral(red: 0, green: 0.5031654835, blue: 0.6585566401, alpha: 1) { didSet { applyStyle() } }

    /**
     Accessibility label when permissions is not authorized yet
     */
    public var allowAccessibilityLabel: String? { didSet { applyStyle() } }

    /**
     Accessibility label when permissions is authorized
     */
    public var allowedAccessibilityLabel: String? { didSet { applyStyle() } }

    /**
     Accessibility identifier when permissions is not authorized yet
     */
    public var allowedAccessibilityIdentifier: String? { didSet { applyStyle() } }

    /**
     Accessibility identifier when permissions is authorized
     */
    public var allowAccessibilityIdentifier: String? { didSet { applyStyle() } }

    /**
     Button has 2 styles: `.base` & `.allowed`.
     For each style can set title and colors.
     */
    var style: Style = .base {
        didSet {
            titleLabel?.adjustsFontForContentSizeCategory = true
            titleLabel?.font = .custom(.bold, size: 14, forTextStyle: .body)
            contentEdgeInsets = UIEdgeInsets(top: 9, left: 15, bottom: 9, right: 15)

            switch style {
            case .base:
                accessibilityIdentifier = allowAccessibilityIdentifier
                accessibilityLabel = allowAccessibilityLabel
                setTitle(allowTitle, for: .normal)
                setTitleColor(allowTitleColor, for: .normal)
                setTitleColor(allowTitleColor.withAlphaComponent(0.7), for: .highlighted)
                backgroundColor = allowBackgroundColor
            case .allowed:
                accessibilityIdentifier = allowedAccessibilityIdentifier
                accessibilityLabel = allowedAccessibilityLabel
                setTitle(allowedTitle, for: .normal)
                backgroundColor = allowedBackgroundColor
                setTitleColor(allowedTitleColor, for: .normal)
                setTitleColor(allowedTitleColor.withAlphaComponent(0.7), for: .highlighted)
            }
        }
    }

    /**
     Ovveride for always uppercased title.
     */
    override public func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title?.uppercased(), for: state)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
    }

    /**
     Animatable update button style.
     */
    public func setStyle(_ style: Style, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.style = style
            })
        } else {
            self.style = style
        }
    }

    private func applyStyle() {
        let current = style
        style = current
    }

    /**
     Button style.
     */
    enum Style {
        case base
        case allowed
    }
}
