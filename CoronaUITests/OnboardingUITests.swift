import UIKit
import XCTest

class OnboardingUITests: XCTestCase {

    let app = XCUIApplication()
    let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let language = Locale(identifier: Locale.preferredLanguages.first!).languageCode!

    // MARK: - Setup
    override func setUp() {
        super.setUp()

        // Exit if a failure was encountered
        continueAfterFailure = false

        // We send a command line argument to our app,
        // to enable it to reset its state
        app.launchArguments.append("--UI-Testing")

        // Add parameter to the launch environment
        app.launchEnvironment[UITestsUtils.hasAcceptedPrivacyPolicyKey] = "NO"
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Tests
    func testShouldNotSkipPrivacyPageWithoutAccepting() {
        // Make sure we're displaying onboarding
        XCTAssertTrue(app.isDisplayingOnboarding)

        // Move to About page
        app.buttons["firstPageNextButton"].tap()
        XCTAssertTrue(app.isDisplayingText("aboutTitle", timeout: 5))

        // Double pressing next button should not skip privacy
        app.buttons["aboutNextButton"].doubleTap()

        XCTAssertTrue(app.isDisplayingText("privacyTitle", timeout: 5))

        // Swiping to left should not skip privacy
        app.swipeLeft()
        app.swipeLeft()

        XCTAssertTrue(app.isDisplayingText("privacyTitle", timeout: 5))
        XCTAssertTrue(app.isDisplayingText("privacyTextTop"))
        XCTAssertTrue(app.isDisplayingText("privacyTextMiddle"))
        XCTAssertTrue(app.isDisplayingText("privacyTextBottom"))
    }

    func testShouldResetOnboardingWhenDecliningPrivacyPolicy() {
        moveToPrivacyPolicyPage()
        app.buttons["privacyButton"].tap()

        // Decline privacy policy
        XCTAssertTrue(app.isDisplayingText("privacyPolicyTitle", timeout: 5))
        app.buttons["declinePrivacyButton"].tap()
        app.tapAlertAction(index: 0)

        // Onboarding reset - Assert on first page
        XCTAssertTrue(app.isDisplayingText("firstPageTitle", timeout: 5))
        XCTAssertFalse(app.isDisplayingText("permissionsTitle"))
    }

    func testShouldPassPrivacyWhenDecliningButAccepts() {
        moveToPrivacyPolicyPage()
        app.buttons["privacyButton"].tap()

        // Press decline but accept
        XCTAssertTrue(app.isDisplayingText("privacyPolicyTitle", timeout: 5))
        app.buttons["declinePrivacyButton"].tap()
        app.tapAlertAction(index: 1)

        // Assert that not on Privacy page
        XCTAssertTrue(app.isDisplayingText("ageVerificationTitle", timeout: 5))
    }

    func testShouldPassPrivacyWhenAccepting() {
        moveToPrivacyPolicyPage()
        app.buttons["privacyButton"].tap()

        // Accept privacy policy
        XCTAssertTrue(app.isDisplayingText("privacyPolicyTitle", timeout: 5))
        app.buttons["acceptPrivacyButton"].tap()

        // Assert that not on Privacy page
        XCTAssertTrue(app.isDisplayingText("ageVerificationTitle", timeout: 5))
    }

    func testShouldEnableAllPermissions() {
        UITestsUtils.resetLocationAndPrivacyWarnings(settings, language)
        app.activate()
        moveToPermissionsPage()

        // Allow Location services
        XCTAssertTrue(app.isDisplayingButton("permissionsLocationButtonAllow"))
        app.buttons["permissionsLocationButtonAllow"].tap()
        springboard.tapAlertAction(index: 0)

        XCTAssertTrue(app.isDisplayingButton("permissionsLocationButtonAllowed"))

        // Allow Bluetooth (Is enabled by default in iOS Simulator)
        XCTAssertTrue(app.isDisplayingButton("permissionsBluetoothButtonAllowed"))

        // Allow Notifications
        XCTAssertTrue(app.isDisplayingButton("permissionsNotificationsButtonAllow"))
        app.buttons["permissionsNotificationsButtonAllow"].tap()
        springboard.tapAlertAction(index: 1)

        XCTAssertTrue(app.isDisplayingButton("permissionsNotificationsButtonAllowed"))
    }

    func testShouldCompleteOnboarding() {
        XCTAssertTrue(app.isDisplayingOnboarding)

        XCTAssertTrue(app.isDisplayingText("firstPageTitle"))
        app.buttons["firstPageNextButton"].tap()

        XCTAssertTrue(app.isDisplayingText("aboutTitle", timeout: 5))
        app.buttons["aboutNextButton"].tap()

        XCTAssertTrue(app.isDisplayingText("privacyTitle", timeout: 5))
        app.buttons["privacyButton"].tap()

        XCTAssertTrue(app.isDisplayingText("privacyPolicyTitle", timeout: 5))
        app.buttons["acceptPrivacyButton"].tap()

        XCTAssertTrue(app.isDisplayingText("ageVerificationTitle", timeout: 5))
        setDateOfBirth(app)
        app.buttons["ageVerificationNextButton"].tap()

        XCTAssertTrue(app.isDisplayingText("permissionsTitle", timeout: 5))
        app.buttons["permissionsNextButton"].tap()

        XCTAssertTrue(app.isDisplayingText("registerTitle"))
        app.buttons["registerButton"].tap()
    }

    private func moveToPrivacyPolicyPage() {
        XCTAssertTrue(app.isDisplayingOnboarding)

        XCTAssertTrue(app.isDisplayingText("firstPageTitle"))
        app.buttons["firstPageNextButton"].tap()

        XCTAssertTrue(app.isDisplayingText("aboutTitle", timeout: 5))
        app.buttons["aboutNextButton"].tap()

        XCTAssertTrue(app.isDisplayingText("privacyTitle", timeout: 5))
    }

    private func moveToPermissionsPage() {
        moveToPrivacyPolicyPage()
        app.buttons["privacyButton"].tap()

        XCTAssertTrue(app.isDisplayingText("privacyPolicyTitle", timeout: 5))
        app.buttons["acceptPrivacyButton"].tap()

        XCTAssertTrue(app.isDisplayingText("ageVerificationTitle", timeout: 5))
        setDateOfBirth(app)
        app.buttons["ageVerificationNextButton"].tap()

        XCTAssertTrue(app.isDisplayingText("permissionsTitle", timeout: 5))
    }
}

private func setDateOfBirth(_ app: XCUIApplication){
    app.textFields["ageVerificationTextField"].tap()
    let datePicker = XCUIApplication().datePickers
    let dateComponent = Calendar.current.dateComponents([.day, .month, .year], from: Date())
    datePicker.pickerWheels[String(dateComponent.year!)].adjust(toPickerWheelValue: "2000")

    app.buttons["ageVerificationDoneButton"].tap()
}
