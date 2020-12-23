import Foundation

extension String {
    var capitalizingFirstCharacter: String {
        return prefix(1).uppercased() + dropFirst(1)
    }
}
