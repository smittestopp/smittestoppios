import UIKit

class MonitoringAuthorizationsView: UIView {
    var isBluetoothOn: Bool = false {
        didSet {
            bluetoothChanged()
        }
    }

    var isGpsOn: Bool = false {
        didSet {
            gpsChanged()
        }
    }

    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 30
        return view
    }()

    lazy var bluetoothImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true
        imageView.accessibilityIdentifier = "monitoringBluetoothStatus"
        return imageView
    }()

    lazy var gpsImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true
        imageView.accessibilityIdentifier = "monitoringGpsStatus"
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        [
            bluetoothImageView,
            gpsImageView,
        ].forEach(stackView.addArrangedSubview(_:))

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    private func bluetoothChanged() {
        bluetoothImageView.image = isBluetoothOn ? .appBluetoothOn : .appBluetoothOff
    }

    private func gpsChanged() {
        gpsImageView.image = isGpsOn ? .appGpsOn : .appGpsOff
    }
}
