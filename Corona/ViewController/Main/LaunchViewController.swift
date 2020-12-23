import UIKit

class LaunchViewController: UIViewController {

    var activityIndicator: UIActivityIndicatorView?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // lets hijack the LaunchScreen storyboard so we don't have to repeat this view
        let launchScreen = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
        if let launchView = launchScreen?.view {
            for subview in launchView.subviews {
                if let activityIndicator = subview as? UIActivityIndicatorView {
                    self.activityIndicator = activityIndicator
                }
            }
          view.addSubview(launchView)
        }

        activityIndicator?.accessibilityLabel = "Loading.Title".localized
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        activityIndicator?.startAnimating()
    }
}
