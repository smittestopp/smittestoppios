import UIKit

protocol PagingViewControllerDelegate: class {
    func pagingViewController(_ pagingViewController: PagingViewController,
                              canContinueFrom viewController: UIViewController,
                              fromIndex: Int) -> Bool
}

class PagingViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    var pageControl: UIPageControl = UIPageControl(frame: .zero)

    weak var delegate: PagingViewControllerDelegate?

    var didFinish: (() -> Void)?

    let viewControllers: [UIViewController]
    var pageIndex = 0 {
        didSet {
            guard pageIndex < pageControl.numberOfPages else {
                return
            }

            pageControl.currentPage = pageIndex
        }
    }

    let pageController: UIPageViewController

    init(viewControllers: [UIViewController]) {
        self.viewControllers = viewControllers
        pageController = UIPageViewController(transitionStyle: .scroll,
                                                   navigationOrientation: .horizontal,
                                                   options: nil)
        super.init(nibName: nil, bundle: nil)
        pageController.delegate = self
        pageController.dataSource = self
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        pageController.setViewControllers([viewControllers[0]], direction: .forward, animated: true, completion: nil)
        install(pageController)

        view.addSubview(pageControl)

        let bottomMargin: CGFloat = DeviceTraitsService.shared.hasNotch ? 20 : 0
        pageControl.numberOfPages = viewControllers.count
        pageControl.sizeToFit()
        pageControl.frame.origin.y = view.bounds.size.height - pageControl.frame.size.height - bottomMargin
        pageControl.isUserInteractionEnabled = false
        view.bringSubviewToFront(pageControl)
        super.viewDidLoad()
    }

    public func pageViewController(
        _: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        if let index = self.index(of: viewController) {
            if index == 0 {
                return nil
            }
            return viewControllers[index - 1]
        }
        return nil
    }

    public func pageViewController(_: UIPageViewController,
                                   viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = self.index(of: viewController),
            index + 1 < viewControllers.count {
            let viewControllerToShow = viewControllers[index + 1]
            let canShow = delegate?.pagingViewController(self, canContinueFrom: viewControllers[index], fromIndex: index) ?? true
            return canShow ? viewControllerToShow : nil
        }

        return nil
    }

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   didFinishAnimating _: Bool,
                                   previousViewControllers _: [UIViewController],
                                   transitionCompleted completed: Bool) {
        if !completed {
            return
        }
        if let lastPushedVC = pageViewController.viewControllers?.last {
            if let index = index(of: lastPushedVC) {
                pageIndex = index
            }
        }
    }

    public func pageViewController(_: UIPageViewController,
                                   willTransitionTo _: [UIViewController]) {
    }

    private func index(of viewController: UIViewController) -> Int? {
        for (index, theVC) in viewControllers.enumerated() where viewController == theVC {
            return index
        }
        return nil
    }

    func goToNextPage(animated _: Bool = true, completion _: ((Bool) -> Void)? = nil) {
        goToPageAtIndex(pageIndex + 1)
    }

    func goToPageAtIndex(_ index: Int, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        guard index < viewControllers.count else {
            return
        }

        if pageIndex < index {
            guard delegate?.pagingViewController(self, canContinueFrom: viewControllers[pageIndex], fromIndex: index) ?? true else {
                return
            }
        }

        pageController.isPagingEnabled = false
        pageController.setViewControllers([viewControllers[index]],
                                          direction: index < pageIndex ? .reverse : .forward,
                                          animated: animated,
                                          completion: { finished in
                                            self.pageController.isPagingEnabled = true
                                            completion?(finished)

                                            guard finished else {
                                                return
                                            }

                                            if let currentVC = self.pageController.viewControllers?.first,
                                                let currentIndex = self.index(of: currentVC) {
                                                self.pageIndex = currentIndex
                                            }
        })
    }

    public func refresh() {
        pageController.setViewControllers([viewControllers[pageIndex]], direction: .forward, animated: false, completion: nil)
    }
}

extension UIPageViewController {
    var isPagingEnabled: Bool {
        get {
            var isEnabled: Bool = true
            for view in view.subviews {
                if let subView = view as? UIScrollView {
                    isEnabled = subView.isScrollEnabled
                }
            }
            return isEnabled
        }
        set {
            for view in view.subviews {
                if let subView = view as? UIScrollView {
                    subView.isScrollEnabled = newValue
                }
            }
        }
    }
}
