import UIKit
@testable import Smittestopp

class MockNotificationService: NotificationServiceProviding {
    var authorizationStatus: NotificationService.AuthorizationStatus = .notDetermined

    func requestAuthorization(_: ((Result<Void, NotificationService.AuthError>) -> Void)?) {
    }

    func postBluetoothOff() {
    }

    func postUpdateAvailable() {
    }

    func postAccessRevoked() {
    }

    func removeAllNotifications() {
    }
}
