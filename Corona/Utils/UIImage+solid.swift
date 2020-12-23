import UIKit

extension UIImage {
    static func solid(_ color: UIColor?, size: CGSize = .init(width: 1, height: 1)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color?.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
