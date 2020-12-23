import UIKit
import XCTest

class UITestsUtils {

    static let userKey = "UI-TestingKey_user"
    static let hasAcceptedPrivacyPolicyKey = "UI-TestingKey_hasAcceptedPrivacyPolicy"
    static let isTrackingEnabledKey = "UI-TestingKey_isTrackingEnabled"
    static let dateOfBirthKey = "UI-TestingKey_dateOfBirth"

    static func launchApplication(_ app: XCUIApplication) {
        app.launch()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        var allowBtn = springboard.buttons["Allow While Using App"]
        if allowBtn.exists {
            allowBtn.tap()
        }
        allowBtn = springboard.buttons["Tillat mens appen er i bruk"]
        if allowBtn.exists {
            allowBtn.tap()
        }
    }

    static func turnOnGPSEn(_ settings: XCUIApplication) {
        settings.tables.cells.staticTexts["Privacy"].tap()
        settings.tables.cells.staticTexts["Location Services"].tap()
        if settings.switches["Location Services"].isEnabled == false {
            settings.switches["Location Services"].tap()
        }
    }

    static func turnOnGPSNo(_ settings: XCUIApplication) {
        settings.tables.cells.staticTexts["Personvern"].tap()
        settings.tables.cells.staticTexts["Stedstjenester"].tap()
        if settings.switches["Stedstjenester"].isEnabled == false {
            settings.switches["Stedstjenester"].tap()
        }
    }

    static func turnGPSOnGloballyAndDisableForApp(_ appName: String, _ settings: XCUIApplication, _ language: String) {
        XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 30))

        language == "en" ? turnOnGPSEn(settings) : turnOnGPSNo(settings)
        var neverIdentifier: String
        language == "en" ? (neverIdentifier = "Never") : (neverIdentifier = "Aldri")
        settings.tables.cells.staticTexts[appName].tap()
        settings.tables.cells.staticTexts[neverIdentifier].tap()
    }

    static func turnGPSOnGloballyAndEnableForApp(_ appName: String, _ settings: XCUIApplication, _ language: String) {
        XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 30))

        language == "en" ? turnOnGPSEn(settings) : turnOnGPSNo(settings)
        var alwaysIdentifier: String
        language == "en" ? (alwaysIdentifier = "Always") : (alwaysIdentifier = "Alltid")
        settings.tables.cells.staticTexts[appName].tap()
        settings.tables.cells.staticTexts[alwaysIdentifier].tap()
    }

    static func resetLocationAndPrivacyWarnings(_ settings: XCUIApplication, _ language: String) {
        XCUIApplication().terminate()
        settings.terminate()
        settings.activate()
        XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 30))

        let generalIdentifier = language == "en" ? "General" : "Generelt"
        let resetIdentifier = language == "en" ? "Reset" : "Nullstill"
        let resetLocationlIdentifier = language == "en" ? "Reset Location & Privacy" : "Nullstill Sted og personvern"
        let resetWarningslIdentifier = language == "en" ? "Reset Warnings" : "Nullstill advarsler"

        settings.tables.staticTexts[generalIdentifier].tap()
        settings.tables.staticTexts[resetIdentifier].tap()
        settings.tables.staticTexts[resetLocationlIdentifier].tap()
        settings.buttons[resetWarningslIdentifier].tap()
        settings.terminate()
    }
}
