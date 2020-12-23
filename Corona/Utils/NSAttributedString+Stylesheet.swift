import UIKit

extension NSAttributedString {
    struct Style {
        enum Attribute {
            case fontWeight(BrandonFont.Weight)
            case fontSize(CGFloat)
            case textColor(UIColor)

            var string: String {
                switch self {
                case let .fontWeight(weight):
                    return "font-family: '\(weight.fontName)'"
                case let .fontSize(size):
                    return "font-size: \(size)px"
                case let .textColor(color):
                    return "color: \(color.hexString)"
                }
            }
        }
        let element: String
        let attributes: [Attribute]
    }

    struct Stylesheet {
        let styles: [Style]

        static var standard: Stylesheet {
            Stylesheet(styles: [
                Style(element: "*", attributes: [
                    .fontWeight(.medium),
                    .fontSize(UIFont.scaledSize(14, forTextStyle: .body)),
                    .textColor(.appMainText),
                ]),
                Style(element: "b", attributes: [
                    .fontWeight(.bold),
                    .fontSize(UIFont.scaledSize(14, forTextStyle: .body)),
                ]),
                Style(element: ".salmon", attributes: [
                    .textColor(.appMonitoringPartiallyActivatedText),
                ]),
                Style(element: ".red", attributes: [
                    .textColor(.appMonitoringDeactivatedText),
                ]),
            ])
        }

        var string: String {
            let style =  styles.map { style in
                let attributes = style.attributes.map { $0.string + ";" }.joined(separator: "\n")
                return """
                \(style.element) {
                \(attributes)
                }
                """
            }.joined(separator: "\n")

            return """
            <style>
            \(style)
            </style>
            """
        }
    }
}
