import XCTest

extension XCUIApplication {
    func isDisplayingText(_ textIdentifier: String) -> Bool {
        staticTexts[textIdentifier].exists
    }

    func isDisplayingText(_ textIdentifier: String, timeout: Double) -> Bool {
        staticTexts[textIdentifier].waitForExistence(timeout: timeout)
    }

    func isDisplayingTextField(_ textFieldIdentifier: String) -> Bool {
        textFields[textFieldIdentifier].exists
    }

    func isDisplayingButton(_ buttonIdentifier: String) -> Bool {
        buttons[buttonIdentifier].exists
    }

    func isDisplayingButton(_ buttonIdentifier: String, timeout: Double) -> Bool {
        buttons[buttonIdentifier].waitForExistence(timeout: timeout)
    }

    func isDisplayingImage(_ imageIdentifier: String) -> Bool {
        images[imageIdentifier].exists
    }

    func isDisplayingSwitch(_ switchIdentifier: String) -> Bool {
        switches[switchIdentifier].exists
    }

    var isDisplayingInfo: Bool {
        otherElements["infoView"].exists
    }

    var isDisplayingSettings: Bool {
        otherElements["settingsView"].exists
    }

    var isDisplayingMonitoring: Bool {
        otherElements["monitoringView"].exists
    }

    var isDisplayingOnboarding: Bool {
        otherElements["onboardingView"].exists
    }

    func tapAlertAction(index: Int) -> Void {
        let alert = alerts.element(boundBy: 0)
        alert.buttons.element(boundBy: index).tap()
    }
}
