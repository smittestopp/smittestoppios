import UIKit
import XCTest

class MonitoringUITests: XCTestCase {

    let app = XCUIApplication()
    let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
    let language = Locale(identifier: Locale.preferredLanguages.first!).languageCode!
    private var appName = "Smittestopp"

    // MARK: - Setup
    override func setUp() {
        super.setUp()

        // Exit if a failure was encountered
        continueAfterFailure = false

        // We send a command line argument to our app,
        // to enable it to reset its state
        app.launchArguments.append("--UI-Testing")

        // Add parameter to the launch environment
        app.launchEnvironment[UITestsUtils.hasAcceptedPrivacyPolicyKey] = "YES"
        app.launchEnvironment[UITestsUtils.isTrackingEnabledKey] = "YES"
        app.launchEnvironment[UITestsUtils.userKey] = "+47 12345678"
        app.launchEnvironment[UITestsUtils.dateOfBirthKey] = "12.12.1990"
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Tests
    func testMonitoringPageShouldShowShareButtonWhenActivated() {
        UITestsUtils.launchApplication(app)
        appName = app.label
        settings.launch()
        UITestsUtils.turnGPSOnGloballyAndEnableForApp(appName, settings, language)
        app.activate()

        // Make sure we're displaying monitoring
        XCTAssertTrue(app.isDisplayingMonitoring)

        // General content
        XCTAssertTrue(app.isDisplayingText("monitoringTitle", timeout: 15))
        XCTAssertTrue(app.isDisplayingImage("monitoringImage"))
        XCTAssertTrue(app.isDisplayingText("monitoringStatus"))

        // Content when activated
        XCTAssertTrue(app.isDisplayingText("monitoringActivatedTitle"))
        XCTAssertTrue(app.isDisplayingText("monitoringActivatedText"))
        XCTAssertTrue(app.isDisplayingText("monitoringShareTitle"))
        XCTAssertTrue(app.isDisplayingButton("monitoringShareButton"))
    }

    func testMonitoringPageShouldShowRegisterAgeButtonWhenActivatedAndNotVerified() {
        app.launchEnvironment[UITestsUtils.dateOfBirthKey] = "NONE"
        UITestsUtils.launchApplication(app)
        appName = app.label
        settings.launch()
        UITestsUtils.turnGPSOnGloballyAndEnableForApp(appName, settings, language)
        app.activate()

        // Make sure we're displaying monitoring
        XCTAssertTrue(app.isDisplayingMonitoring)

        // General content
        XCTAssertTrue(app.isDisplayingText("monitoringTitle", timeout: 15))
        XCTAssertTrue(app.isDisplayingImage("monitoringImage"))
        XCTAssertTrue(app.isDisplayingText("monitoringStatus"))

        // Content when activated
        XCTAssertTrue(app.isDisplayingText("monitoringActivatedTitle"))
        XCTAssertTrue(app.isDisplayingText("monitoringActivatedText"))

        // Content when not age verified
        XCTAssertTrue(app.isDisplayingText("monitoringRegisterAgeDescription"))
        XCTAssertTrue(app.isDisplayingButton("ageVerificationExplanationButton"))
        XCTAssertTrue(app.isDisplayingTextField("ageVerificationTextField"))
    }

    func testMonitoringPageShouldOpenSettingsWhenPartiallyActivated() {
        UITestsUtils.launchApplication(app)
        appName = app.label
        settings.launch()
        UITestsUtils.turnGPSOnGloballyAndDisableForApp(appName, settings, language)
        app.activate()

        // Make sure we're displaying monitoring
        XCTAssertTrue(app.isDisplayingMonitoring)

        // Content when partially activated
        XCTAssertTrue(app.isDisplayingText("monitoringPartiallyActivatedText", timeout: 15))
        XCTAssertTrue(app.isDisplayingButton("monitoringSettingsButton"))

        XCTAssertTrue(app.isDisplayingImage("monitoringGpsStatus"))
        XCTAssertTrue(app.isDisplayingImage("monitoringBluetoothStatus"))

        // Open settings on phone
        app.buttons["monitoringSettingsButton"].tap()

        // Check if settings opened
        XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 60))
    }

    func testMonitoringPageShouldRestartMonitoringWhenDeactivated() {
        app.launchEnvironment[UITestsUtils.isTrackingEnabledKey] = "NO"
        UITestsUtils.launchApplication(app)
        appName = app.label
        settings.launch()
        UITestsUtils.turnGPSOnGloballyAndEnableForApp(appName, settings, language)
        app.activate()

        // Make sure we're displaying monitoring
        XCTAssertTrue(app.isDisplayingMonitoring)

        // Assert on content while deactivated
        XCTAssertTrue(app.isDisplayingText("monitoringDeactivatedText", timeout: 15))
        XCTAssertTrue(app.isDisplayingButton("monitoringRestartButton"))

        XCTAssertFalse(app.isDisplayingText("monitoringActivatedTitle"))
        XCTAssertFalse(app.isDisplayingText("monitoringActivatedText"))
        XCTAssertFalse(app.isDisplayingText("monitoringShareTitle"))
        XCTAssertFalse(app.isDisplayingButton("monitoringShareButton"))

        // Click restart monitoring button
        XCTAssertTrue(app.isDisplayingButton("monitoringRestartButton"))
        app.buttons["monitoringRestartButton"].tap()

        // Assert on content
        XCTAssertFalse(app.isDisplayingText("monitoringDeactivatedText", timeout: 5))
        XCTAssertFalse(app.isDisplayingButton("monitoringRestartButton"))

        XCTAssertTrue(app.isDisplayingText("monitoringActivatedText"))
        XCTAssertTrue(app.isDisplayingText("monitoringActivatedTitle"))
        XCTAssertTrue(app.isDisplayingText("monitoringShareTitle"))
        XCTAssertTrue(app.isDisplayingButton("monitoringShareButton"))
    }

    func testMonitoringPageShouldOpenPhoneSettings() {
        UITestsUtils.launchApplication(app)
        appName = app.label
        settings.launch()
        UITestsUtils.turnGPSOnGloballyAndDisableForApp(appName, settings, language)
        app.activate()

        // Make sure we're displaying monitoring
        XCTAssertTrue(app.isDisplayingMonitoring)

        // Open settings on phone
        XCTAssertTrue(app.isDisplayingButton("monitoringSettingsButton", timeout: 15))
        app.buttons["monitoringSettingsButton"].tap()

        // Check if settings opened
        XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 60))
    }
}
