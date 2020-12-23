import UIKit

extension NSMutableAttributedString {
    static func fromHTML(_ text: String, style: Stylesheet) -> NSMutableAttributedString {
        let textWithStylesheet = style.string + text

        guard let data = textWithStylesheet.data(using: .utf8) else {
            Logger.warning("Failed to get data buffer", tag: "NSAttributedString")
            return .init(string: text)
        }

        do {
            return try NSMutableAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue),
                ],
                documentAttributes: nil)
        } catch {
            Logger.warning("Failed to create attributed string from text", tag: "NSAttributedString")
            return .init(string: text)
        }
    }
}
