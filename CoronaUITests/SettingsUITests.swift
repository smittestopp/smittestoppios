import UIKit
import XCTest

class SettingsUITests: XCTestCase {

    let app = XCUIApplication()
    let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")

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
        app.launchEnvironment[UITestsUtils.dateOfBirthKey] = "14.12.1957"
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Tests
    func testSettingsPageShouldContainContent() {
        UITestsUtils.launchApplication(app)
        app.tabBars.buttons["settingsTab"].tap()

        // Make sure we're displaying settings
        XCTAssertTrue(app.isDisplayingSettings)

        // Check for content
        XCTAssertTrue(app.isDisplayingText("settingsTitle"))
        XCTAssertTrue(app.isDisplayingText("settingsAppVersion"))

        XCTAssertTrue(app.isDisplayingText("settingsUserTitle"))
        XCTAssertTrue(app.isDisplayingText("settingsUserPhoneNumber"))
        XCTAssertTrue(app.isDisplayingButton("settingsLogoutButton"))

        XCTAssertTrue(app.isDisplayingText("settingsMonitoringTitle"))

        XCTAssertTrue(app.isDisplayingText("settingsSupportTitle"))
        XCTAssertTrue(app.isDisplayingButton("settingsSupportLink"))
        XCTAssertTrue(app.isDisplayingButton("settingsSupportPhoneNumber"))

        XCTAssertTrue(app.isDisplayingButton("settingsDeleteDataButton"))
    }

    func testSettingsPageRedirectsToCorrectLink() {
        UITestsUtils.launchApplication(app)
        app.tabBars.buttons["settingsTab"].tap()

        // Make sure we're displaying settings
        XCTAssertTrue(app.isDisplayingSettings)

        app.buttons["settingsSupportLink"].tap()

        // Assert safari is running in foreground before checking URL
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 30))
        XCTAssertTrue(safari.otherElements["Address"].waitForExistence(timeout: 30))
        safari.otherElements["Address"].tap()
        let url = safari.textFields["URL"].value! as! String

        XCTAssertEqual(url, "https://helsenorge.no/kontakt")
    }

    func testDeleteData() {
        UITestsUtils.launchApplication(app)
        app.tabBars.buttons["settingsTab"].tap()

        // Make sure we're displaying settings
        XCTAssertTrue(app.isDisplayingSettings)

        app.buttons["settingsDeleteDataButton"].tap()
        app.tapAlertAction(index: 1)

        // Check if still in settings
        XCTAssertTrue(app.isDisplayingSettings)
    }

    func testDeleteDataAndAbort() {
        UITestsUtils.launchApplication(app)
        app.tabBars.buttons["settingsTab"].tap()

        // Make sure we're displaying settings
        XCTAssertTrue(app.isDisplayingSettings)

        app.buttons["settingsDeleteDataButton"].tap()
        app.tapAlertAction(index: 0)

        // Check if still in settings
        XCTAssertTrue(app.isDisplayingSettings)
    }

    func testLogout() {
        UITestsUtils.launchApplication(app)
        app.tabBars.buttons["settingsTab"].tap()

        // Make sure we're displaying settings
        XCTAssertTrue(app.isDisplayingSettings)

        // Log out
        app.buttons["settingsLogoutButton"].tap()
        app.tapAlertAction(index: 1)

        // Check if app logs out and shows onboarding
        XCTAssertFalse(app.isDisplayingSettings)
        XCTAssertTrue(app.isDisplayingOnboarding)
    }

    func testLogoutAndAbort() {
        UITestsUtils.launchApplication(app)
        app.tabBars.buttons["settingsTab"].tap()

        // Make sure we're displaying settings
        XCTAssertTrue(app.isDisplayingSettings)

        // Log out
        app.buttons["settingsLogoutButton"].tap()
        app.tapAlertAction(index: 0)

        // Check if app logs out and shows onboarding
        XCTAssertFalse(app.isDisplayingOnboarding)
        XCTAssertTrue(app.isDisplayingSettings)
    }

    func testToggleMonitoring() {
        UITestsUtils.launchApplication(app)

        // Make sure monitoring is not switched off
        XCTAssertFalse(app.isDisplayingButton("monitoringRestartButton"))

        // Move to settings and switch monitoring off
        app.tabBars.buttons["settingsTab"].tap()
        XCTAssertTrue(app.isDisplayingSettings)
        app.switches["settingsMonitoringSwitch"].tap()

        // Check if monitoring is switched off
        app.tabBars.buttons["monitoringTab"].tap()
        XCTAssertTrue(app.isDisplayingMonitoring)
        XCTAssertTrue(app.isDisplayingButton("monitoringRestartButton"))

        // Switch Monitoring back on
        app.tabBars.buttons["settingsTab"].tap()
        app.switches["settingsMonitoringSwitch"].tap()

        // Check if monitoring is switched on
        app.tabBars.buttons["monitoringTab"].tap()
        XCTAssertTrue(app.isDisplayingMonitoring)
        XCTAssertFalse(app.isDisplayingButton("monitoringRestartButton"))
    }

    func testSettingsOpenAndClosePrivacyPolicy() {
        UITestsUtils.launchApplication(app)
        app.tabBars.buttons["settingsTab"].tap()

        // Make sure we're displaying settings
        XCTAssertTrue(app.isDisplayingSettings)

        // Open privacy policy
        app.buttons["settingsPrivacyButton"].tap()

        // Assert that privacy policy is shown
        XCTAssertTrue(app.staticTexts["privacyPolicyTitle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.isDisplayingButton("closePrivacyButton"))

        // Close privacy
        app.buttons["closePrivacyButton"].tap()

        XCTAssertFalse(app.isDisplayingButton("closePrivacyButton"))
    }
}
