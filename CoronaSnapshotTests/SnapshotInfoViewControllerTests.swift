import Foundation
import SnapshotTesting
import XCTest
@testable import Smittestopp

class SnapshotInfoViewControllerTests: XCTestCase {
    func testSnapshot() {
        let vc = InfoViewController()
        assertSnapshotsWithTraits(matching: vc)
    }
}
