import UIKit

protocol WithReuseIdentifier: class {
    static var reuseIdentifier: String { get }
}

extension WithReuseIdentifier {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UITableView {
    func register<T: WithReuseIdentifier>(_: T.Type) {
        register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
    }

    func dequeue<T: WithReuseIdentifier>(_ indexPath: IndexPath, _: T.Type) -> T {
        return dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }
}
