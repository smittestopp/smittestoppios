import UIKit

extension UIColor {
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgba = Int(r * 255) << 24 | Int(g * 255) << 16 | Int(b * 255) << 8 | Int(a * 255)
        return String(format: "#%08x", arguments: [rgba])
    }
}
