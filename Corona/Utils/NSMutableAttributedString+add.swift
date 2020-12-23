import UIKit

extension NSMutableAttributedString {
    private var whole: NSRange {
        return NSRange(location: 0, length: length)
    }

    func add(font value: UIFont) -> NSMutableAttributedString {
        addAttribute(.font, value: value, range: whole)
        return self
    }

    func add(textColor value: UIColor?) -> NSMutableAttributedString {
        if let value = value {
            addAttribute(.foregroundColor, value: value, range: whole)
        }
        return self
    }

    func add(paragraphStyle value: NSParagraphStyle) -> NSMutableAttributedString {
        addAttribute(.paragraphStyle, value: value, range: whole)
        return self
    }
}
