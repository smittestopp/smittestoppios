import SnapshotTesting
import UIKit
import XCTest

func assertSnapshotsWithTraits<Value: UIViewController>(
    matching value: @autoclosure () throws -> Value,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line) {
    let size = CGSize(width: 480, height: 3000)
    let traits: [String: UITraitCollection] = [
        "small": .init(preferredContentSizeCategory: .small),
        "extraExtraLarge": .init(preferredContentSizeCategory: .extraExtraLarge),
        "accessibilityExtraExtraExtraLarge": .init(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge),
    ]

    try! traits.forEach { traitName, trait in
        assertSnapshot(
            matching: try value(),
            as: .image(size: size, traits: trait),
            named: "\(traitName).\(Locale.current.languageCode!)",
            file: file,
            testName: testName,
            line: line)
    }
}
