import UIKit

extension UIView {

    private static let loadingIndicatorTag = 10001
    private static let overlayTag = 10002

    private var loadingIndicator: UIActivityIndicatorView? {
        return viewWithTag(UIView.loadingIndicatorTag) as? UIActivityIndicatorView
    }

    private var overlayView: UIView? {
        return viewWithTag(UIView.overlayTag)
    }

    /// Adds UIActivityIndicatorView as a subview when true.
    var isLoadingIndicatorVisible: Bool {
        get {
            return loadingIndicator != nil
        }
        set {
            if newValue {
                guard loadingIndicator == nil else { return }
                let overlayView = UIView(frame: bounds)
                overlayView.tag = UIView.overlayTag
                overlayView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
                addSubview(overlayView)

                var indicator: UIActivityIndicatorView
                if #available(iOS 13.0, *) {
                    indicator = UIActivityIndicatorView(style: .large)
                } else {
                    indicator = UIActivityIndicatorView(style: .whiteLarge)
                }

                indicator.accessibilityLabel = "Loading.Title".localized
                indicator.tag = UIView.loadingIndicatorTag
                indicator.frame = CGRect(x: bounds.origin.x,
                                         y: bounds.origin.y - 80,
                                         width: bounds.size.width,
                                         height: bounds.size.height)
                addSubview(indicator)
                indicator.startAnimating()
            } else {
                loadingIndicator?.removeFromSuperview()
                overlayView?.removeFromSuperview()
            }
        }
    }
}

public protocol ShowsLoadingState: class {
    func setLoadingState<LoadingValue, LoadingError>(_ state: LoadingState<LoadingValue, LoadingError>)
}

extension UIViewController: ShowsLoadingState {

    public func setLoadingState<LoadingValue, LoadingError>(_ state: LoadingState<LoadingValue, LoadingError>) {
        switch state {
        case .loading:
            view.isLoadingIndicatorVisible = true
        case .reloading:
            view.isLoadingIndicatorVisible = true
        case .loaded:
            view.isLoadingIndicatorVisible = false
        case .failed(let error):
            view.isLoadingIndicatorVisible = false
            displayError(error)
        }
    }

    public func displayError(_ error: Error) {
        presentErrorAlert(error: error)
    }

    func presentErrorAlert(error: Error) {
        let alertController = UIAlertController(
            title: "Error.Title".localized,
            message: "Error.Description".localized + "\n\n" + error.localizedDescription,
            preferredStyle: .alert
        )
        alertController.addAction(.init(title: "OKButton.Title".localized, style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }

}

public enum LoadingState<LoadingValue, LoadingError: Error> {

    /// Value is loading.
    case loading

    /// Value is reloading.
    case reloading

    /// Value is loaded.
    case loaded(LoadingValue)

    /// Value loading failed with the given error.
    case failed(LoadingError)
}
