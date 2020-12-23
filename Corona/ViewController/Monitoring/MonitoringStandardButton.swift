import UIKit

class MonitoringStandardButton: MultilineButton {
    override func setup() {
        super.setup()

        layer.cornerRadius = 8
        clipsToBounds = true

        setBackgroundImage(.solid(.appMonitoringButtonNormalBackground), for: .normal)
        setBackgroundImage(.solid(.appMonitoringButtonHighlightedBackground), for: .highlighted)

        setTitleColor(.appMonitoringButtonText, for: .normal)

        titleLabel?.font = .custom(.medium, size: 14, forTextStyle: .body)

        contentEdgeInsets = UIEdgeInsets(top: 13, left: 9, bottom: 13, right: 9)

        heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
    }
}
