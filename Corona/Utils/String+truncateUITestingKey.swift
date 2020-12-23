import Foundation

extension String {
    func truncateUITestingKey() -> String {
        if let range = self.range(of: AppDelegate.uiTestingKeyPrefix) {
            let userDefaultsKey = self[range.upperBound...]
            return String(userDefaultsKey)
        }
        return self
    }
}
