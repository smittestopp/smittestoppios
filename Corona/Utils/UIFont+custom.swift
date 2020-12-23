import UIKit

enum BrandonFont { }

extension BrandonFont {
    enum Weight: String {
        case black
        case blackItalic
        case bold
        case boldItalic
        case light
        case lightItalic
        case medium
        case mediumItalic
        case regular
        case regularItalic
        case thin
        case thinItalic

        var fontName: String {
            return "BrandonText-\(rawValue.capitalizingFirstCharacter)"
        }
    }
}

extension UIFont {
    static func scaledSize(_ size: CGFloat, forTextStyle textStyle: UIFont.TextStyle) -> CGFloat {
        return UIFontMetrics(forTextStyle: textStyle).scaledValue(for: size)
    }

    static func custom(_ weight: BrandonFont.Weight, size: CGFloat, forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
        guard let font = UIFont(name: weight.fontName, size: size) else {
            Logger.warning("Cannot find font \"\(weight.fontName)\" in the bundle", tag: "UIFont")
            assertionFailure()
            return .systemFont(ofSize: size, weight: .regular)
        }

        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
    }
}
