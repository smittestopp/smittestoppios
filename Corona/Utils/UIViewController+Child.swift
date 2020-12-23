import UIKit

public extension UIViewController {
    func install(_ child: UIViewController, onView view: UIView? = nil) {
        addChild(child)

        child.view.translatesAutoresizingMaskIntoConstraints = false

        let viewToUse: UIView = view ?? self.view

        viewToUse.addSubview(child.view)

        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: viewToUse.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: viewToUse.trailingAnchor),
            child.view.topAnchor.constraint(equalTo: viewToUse.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: viewToUse.bottomAnchor),
        ])

        child.didMove(toParent: self)
    }

    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}
