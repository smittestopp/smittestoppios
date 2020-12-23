import UIKit

/// UILabel that can be tapped on to copy its content
class CopyableLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isUserInteractionEnabled = true
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }

    private func showMenu() {
        becomeFirstResponder()

        guard !UIMenuController.shared.isMenuVisible else {
            return
        }
        UIMenuController.shared.setTargetRect(bounds, in: self)
        UIMenuController.shared.setMenuVisible(true, animated: true)
    }

    @objc private func tapped() {
        showMenu()
    }

    override func copy(_: Any?) {
        UIPasteboard.general.string = text
    }
}
