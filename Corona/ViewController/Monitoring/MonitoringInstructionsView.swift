import UIKit

fileprivate extension LocationDisabledReason {
    var instructions: [MonitoringInstructionsView.Instruction] {
        switch self {
        case .locationServicesDisabled:
            return [
                .init(description: "Monitoring.Instructions.Settings".localized, icon: .appSettingsIcon),
                .init(description: "Monitoring.Instructions.Privacy".localized, icon: .appPrivacyIcon),
                .init(description: "Monitoring.Instructions.Location".localized, icon: .appLocationIcon),
                .init(description: "Monitoring.Instructions.Turn.On".localized, icon: .appTurnOnIcon),
            ]
        case .systemSettingsSetToAlways:
            return [
                .init(description: "Monitoring.Instructions.Location".localized, icon: .appLocationIcon),
                .init(description: "Monitoring.Instructions.Always.On".localized, icon: .appBlankIcon),
            ]
        }
    }
}

fileprivate extension BluetoothDisabledReason {
    var instructions: [MonitoringInstructionsView.Instruction] {
        switch self {
        case .globallyDisabled:
            return [
                .init(description: "Monitoring.Instructions.Settings".localized, icon: .appSettingsIcon),
                .init(description: "Monitoring.Instructions.Bluetooth".localized, icon: .appBluetoothIcon),
                .init(description: "Monitoring.Instructions.Turn.On".localized, icon: .appTurnOnIcon),
            ]
        case .systemSettingsSetToEnabled:
            return [
                .init(description: "Monitoring.Instructions.Bluetooth".localized, icon: .appBluetoothIcon),
                .init(description: "Monitoring.Instructions.Turn.On".localized, icon: .appTurnOnIcon),
            ]
        }
    }
}

class MonitoringInstructionsView: UIView {
    enum InstructionType {
        case location(LocationDisabledReason)
        case bluetooth(BluetoothDisabledReason)
        case both(LocationDisabledReason, BluetoothDisabledReason)
    }

    struct Instruction {
        let description: String
        let icon: UIImage
    }

    var instructionType: InstructionType? {
        didSet {
            instructionTypeChanged()
        }
    }

    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .center
        view.spacing = 0
        return view
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
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: nil) { [weak self] _ in
                self?.updateContentForContentSizeCategory()
        }
    }

    var instructionsStylesheet: NSMutableAttributedString.Stylesheet {
        .init(styles: [
            .init(element: "*", attributes: [
                .fontWeight(.medium),
                .fontSize(UIFont.scaledSize(18, forTextStyle: .body)),
                .textColor(.appMainText),
            ]),
            .init(element: "b", attributes: [
                .fontWeight(.bold),
            ]),
        ])
    }

    private func makeLabel(_ htmlText: String) -> UILabel {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.attributedText = NSMutableAttributedString
            .fromHTML(htmlText, style: instructionsStylesheet)
            .add(paragraphStyle: NSMutableParagraphStyle()
                .with(alignment: .center))
        label.accessibilityIdentifier = "monitoringPartiallyActivatedText"
        return label
    }

    private func makeInstructions(_ instructions: [Instruction]) -> [UIView] {
        var instructionLabels: [UIView] = []
        for (index, instruction) in instructions.enumerated() {
            instructionLabels.append(makeInstructionLabel(instruction: instruction, listNumber: index + 1))
            instructionLabels.append(makeSpacer(height: 10))
        }
        instructionLabels.append(makeSpacer(height: 30))

        return instructionLabels
    }

    private func makeInstructionLabel(instruction: Instruction, listNumber: Int) -> UILabel {
        let instructionLabel = UILabel()
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.font = .custom(.bold, size: 18, forTextStyle: .body)
        instructionLabel.numberOfLines = 0
        instructionLabel.textColor = .appMainText
        instructionLabel.widthAnchor.constraint(equalToConstant: 225).isActive = true

        let iconTextAttachment = NSTextAttachment()
        iconTextAttachment.image = instruction.icon
        iconTextAttachment.bounds = CGRect(x: 0, y: -9.0, width: iconTextAttachment.image!.size.width, height: iconTextAttachment.image!.size.height)
        let iconAsString = NSAttributedString(attachment: iconTextAttachment)
        let formattedDescription = "     \(listNumber). \(instruction.description)"

        let instructionStringWithIcon = NSMutableAttributedString()
        instructionStringWithIcon.append(iconAsString)
        instructionStringWithIcon.append(NSAttributedString(string: formattedDescription))

        instructionLabel.attributedText = instructionStringWithIcon
        return instructionLabel
    }

    private func makeOpenSettingsButton() -> UIButton {
        let button = MonitoringStandardButton()
        button.setTitle("Monitoring.Instructions.OpenSettings.Button.Title".localized, for: .normal)
        button.titleLabel?.font = .custom(.regular, size: 16, forTextStyle: .body)
        button.addTarget(self, action: #selector(openSettingsTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "monitoringSettingsButton"
        return button
    }

    private func makeSpacer(height: CGFloat) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    private func instructionTypeChanged() {
        guard let instructionType = instructionType else {
            return
        }

        let views: [UIView]

        stackView.removeAllArrangedSubviews()

        switch instructionType {
        case let .bluetooth(bluetooth):
            switch bluetooth {
            case .globallyDisabled:
                views = [
                    makeLabel("Monitoring.Instructions.Bluetooth.Off.Global".localized),
                    makeSpacer(height: 24)]
                    + makeInstructions(bluetooth.instructions)
            case .systemSettingsSetToEnabled:
                views = [
                    makeLabel("Monitoring.Instructions.Bluetooth.Off.Local".localized),
                    makeSpacer(height: 24)]
                    + makeInstructions(bluetooth.instructions)
                    + [
                    makeOpenSettingsButton(),
                    makeSpacer(height: 40),
                ]
            }
        case let .location(location):
            switch location {
            case .locationServicesDisabled:
                views = [
                    makeLabel("Monitoring.Instructions.GPS.Off.Global".localized),
                    makeSpacer(height: 24)]
                    + makeInstructions(location.instructions)
            case .systemSettingsSetToAlways:
                views = [
                    makeLabel("Monitoring.Instructions.GPS.Off.Local".localized),
                    makeSpacer(height: 24)]
                    + makeInstructions(location.instructions)
                    + [
                    makeOpenSettingsButton(),
                    makeSpacer(height: 40),
                ]
            }
        case let .both(location, bluetooth):
            let first: String
            let second: String

            let shouldShouldOpenSettingsButton: Bool

            switch (bluetooth, location) {
            case (.globallyDisabled, .locationServicesDisabled):
                first = "Monitoring.Instructions.BluetoothAndGPS.Off.Global.PartOne".localized
                second = "Monitoring.Instructions. BluetoothAndGPS.Off.Global.PartTwo".localized
                shouldShouldOpenSettingsButton = false
            default:
                first = "Monitoring.Instructions.BluetoothAndGPS.Off.Local.PartOne".localized
                second = "Monitoring.Instructions.BluetoothAndGPS.Off.Local.PartTwo".localized
                shouldShouldOpenSettingsButton = true
            }

            views = [
                makeLabel(first),
                makeSpacer(height: 24)]
                + makeInstructions(location.instructions)
                + [
                makeLabel(second),
                makeSpacer(height: 24)]
                + makeInstructions(bluetooth.instructions)
                + (shouldShouldOpenSettingsButton ?
                [
                    makeOpenSettingsButton(),
                    makeSpacer(height: 40),
                ]
                :
                [])
        }

        views.forEach(stackView.addArrangedSubview(_:))

        views.compactMap { $0 as? UIImageView }.forEach { imageView in
            imageView.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.8).isActive = true
            guard let imageSize = imageView.image?.size else {
                assertionFailure()
                return
            }

            let aspectRatio: CGFloat = imageSize.height / imageSize.width
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: aspectRatio).isActive = true
        }

        views.compactMap { $0 as? UIButton }.forEach { button in
            button.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        }
    }

    @objc private func openSettingsTapped() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsURL, options: [:]) { _ in
            Logger.warning("Failed to open Settings", tag: "instructions")
        }
    }

    private func updateContentForContentSizeCategory() {
        instructionTypeChanged()
    }
}
