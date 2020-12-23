import UIKit
import XCTest

class InfoUITests: XCTestCase {

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
        app.launchEnvironment[UITestsUtils.userKey] = "+47 12345678"
        UITestsUtils.launchApplication(app)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Tests

    func testInfoPageShouldContainContent() {
        app.tabBars.buttons["infoTab"].tap()

        // Make sure we're displaying info
        XCTAssertTrue(app.isDisplayingInfo)

        // Check for content
        XCTAssertTrue(app.isDisplayingText("infoTitle"))

        XCTAssertTrue(app.isDisplayingButton("infoLinkInformation"))
        XCTAssertTrue(app.isDisplayingButton("infoLinkSmittestopp"))
        XCTAssertTrue(app.isDisplayingButton("infoLinkTools"))
        XCTAssertTrue(app.isDisplayingButton("infoLinkSelfReport"))
    }

    func testInfoPageLinksRedirectToCorrectPage() {
        app.tabBars.buttons["infoTab"].tap()

        // Make sure we're displaying info
        XCTAssertTrue(app.isDisplayingInfo)

        // Test first link
        isCorrectLink(identifier: "infoLinkInformation", urlToAssert: "https://helsenorge.no/koronavirus")

        // Test second link
        isCorrectLink(identifier: "infoLinkSmittestopp", urlToAssert: "https://helsenorge.no/smittestopp")

        // Test third link
        isCorrectLink(identifier: "infoLinkTools", urlToAssert: "https://helsenorge.no/koronavirus/koronaverktoy")

        // Test fourth link
        isCorrectLink(identifier: "infoLinkSelfReport", urlToAssert: "https://helsenorge.no/koronavirus/koronasmitte")
    }

    private func isCorrectLink(identifier: String, urlToAssert: String) {
        app.buttons[identifier].tap()

        // Assert safari is running in foreground before checking URL
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 30))

        XCTAssertTrue(safari.otherElements["Address"].waitForExistence(timeout: 30))
        safari.otherElements["Address"].tap()
        let url = safari.textFields["URL"].value! as! String

        XCTAssertEqual(url, urlToAssert)

        // Return to Smittestopp
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30))
    }
}
