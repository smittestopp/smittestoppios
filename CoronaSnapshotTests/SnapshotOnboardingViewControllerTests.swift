import Foundation
import SnapshotTesting
import XCTest
@testable import Smittestopp

class SnapshotOnboardingViewControllerTests: XCTestCase {
    struct MockDependencyContainer: OnboardingViewController.Dependencies {
        var mockLocationManager = MockLocationManager()
        var mockNotificationService = MockNotificationService()
        var mockLocalStorage = MockLocalStorageService()
        var mockApiService = MockApiService()
        var mockLoginService = MockLoginService()
        var mockBundleService = MockBundleService()

        var locationManager: LocationManagerProviding { return mockLocationManager }
        var notificationService: NotificationServiceProviding { return mockNotificationService }
        var localStorage: LocalStorageServiceProviding { return mockLocalStorage }
        var apiService: ApiServiceProviding { return mockApiService }
        var loginService: LoginServiceProviding { return mockLoginService }
        var bundle: BundleServiceProviding { return mockBundleService }
    }

    func testNumberOfPages() {
        XCTAssertNotNil(BundleService().onboarding)
        // In case we add more onboarding pages and forget to add tests catch it here.
        XCTAssertEqual(BundleService().onboarding!.pages.count, 6)
    }

    func snapshot(page: Int, dependencies: MockDependencyContainer = MockDependencyContainer(),
                  file: StaticString = #file, testName: String = #function, line: UInt = #line) {
        let allPages = BundleService().onboarding!.pages
        XCTAssert(page >= 0)
        XCTAssert(page < allPages.count)

        let page = allPages[page]
        dependencies.mockBundleService.onboarding = Onboarding(pages: [page])

        let vc = OnboardingViewController(
            dependencies: dependencies,
            shouldShowRegistrationPage: false,
            shouldShowTokenExpiredAlert: false)

        assertSnapshot(matching: vc, as: .image, named: Locale.current.languageCode!,
                       file: file, testName: testName, line: line)
    }

    func testPage1YourHelpMatters() {
        snapshot(page: 0)
    }

    func testPage2About() {
        snapshot(page: 1)
    }

    func testPage3Privacy() {
        snapshot(page: 2)
    }

    func testPage4AgeVerification() {
        snapshot(page: 3)
    }

    func testPage5Permissions() {
        let deps = MockDependencyContainer()
        deps.mockLocationManager.bluetoothState = .init(authorization: .allowedAlways, power: .on)
        deps.mockLocationManager.gpsState = .init(authorizationStatus: .notDetermined, isLocationServiceEnabled: true)
        deps.mockNotificationService.authorizationStatus = .authorized

        snapshot(page: 4, dependencies: deps)
    }

    func testPage6Messages() {
        snapshot(page: 5)
    }

    func testPrivacyPolicy() {
        let privacyPolicyHTML = BundleService().privacyPolicyHTML
        XCTAssertNotNil(privacyPolicyHTML)

        let vc = OnboardingPrivacyPolicyViewController(privacyPolicyHTML: privacyPolicyHTML!, acceptBlock: {}, denyBlock: {})

        let size = CGSize(width: 480, height: 8000)
        assertSnapshot(matching: vc, as: .image(size: size), named: Locale.current.languageCode!)
    }
}
