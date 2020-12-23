import Foundation
import UIKit
import UserNotifications

fileprivate extension String {
    static let tag = "NotificationService"
}

protocol NotificationServiceProviding: class {
    var authorizationStatus: NotificationService.AuthorizationStatus { get }
    func requestAuthorization(_ completion: ((Result<Void, NotificationService.AuthError>)->Void)?)
    func postBluetoothOff()
    func postUpdateAvailable()
    func postAccessRevoked()
    func removeAllNotifications()
}

protocol HasNotificationService {
    var notificationService: NotificationServiceProviding { get }
}

class NotificationService: NSObject, NotificationServiceProviding {
    static let shared: NotificationService = .init()

    enum AuthError: Error {
        case requestError(Error)
        case notGranted
    }

    var authorizationStatus: AuthorizationStatus {
        guard let authorizationStatus = fetchAuthorizationStatus() else { return .notDetermined }
        return NotificationService.AuthorizationStatus(authorizationStatus)
    }

    enum AuthorizationStatus {
        case notDetermined
        case denied
        case authorized
        case provisional

        var isAuthorized: Bool {
            return self == .authorized
        }
    }

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization(_ completion: ((Result<Void, NotificationService.AuthError>)->Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                DispatchQueue.main.async {
                    Logger.warning("Failed to request authorization: \(error)", tag: .tag)
                    completion?(.failure(.requestError(error)))
                }
                return
            }

            DispatchQueue.main.async {
                if granted {
                    completion?(.success(()))
                }
                else {
                    completion?(.failure(.notGranted))
                }
            }
        }
    }

    func postBluetoothOff() {
        let text = "Notification.BluetoothOff".localized

        let oneSecond: TimeInterval = 1
        let thirtyMinutes: TimeInterval = 30 * 60

        hasDeliveredNotifications { hasNotifications in
            if hasNotifications {
                // do not try to deliver yet another notification if there is one already
                return
            }

            self.post(message: text, afterTimeInterval: oneSecond)
            self.post(message: text, afterTimeInterval: thirtyMinutes)
        }
    }

    func postUpdateAvailable() {
        let text = "Notification.NewVersionAvailable".localized

        let tenSeconds: TimeInterval = 10

        hasDeliveredNotifications { hasNotifications in
            if hasNotifications {
                // do not try to deliver yet another notification if there is one already
                return
            }

            self.post(message: text, afterTimeInterval: tenSeconds, identifier: "UPDATE_NOTIFICATION_IDENTIFIER")
        }
    }

    func postAccessRevoked() {
        let text = "Notification.DataDeleted".localized

        let oneSecond: TimeInterval = 1

        hasDeliveredNotifications { hasNotifications in
            if hasNotifications {
                // do not try to deliver yet another notification if there is one already
                return
            }

            self.post(message: text, afterTimeInterval: oneSecond)
        }
    }

    func removeAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }

    private func hasDeliveredNotifications(_ completion: @escaping ((Bool)->Void)) {
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications { notifications in
            // this callback can be called not on the main thread as documented.
            DispatchQueue.main.async {
                completion(!notifications.isEmpty)
            }
        }
    }

    private func post(title: String? = nil, message: String, afterTimeInterval seconds: TimeInterval, identifier: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title ?? ""
        content.body = message

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)

        let notificationIdentifier = identifier ?? UUID().uuidString
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.add(request) { error in
            if let error = error {
                Logger.warning("Failed to schedule notification: \(error)", tag: .tag)
            }
        }
    }

    private func fetchAuthorizationStatus() -> UNAuthorizationStatus? {
        var notificationSettings: UNNotificationSettings?
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.global().async {
            UNUserNotificationCenter.current().getNotificationSettings { setttings in
                notificationSettings = setttings
                semaphore.signal()
            }
        }

        semaphore.wait()
        return notificationSettings?.authorizationStatus
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Allow displaying notifications while the app is in foreground
        completionHandler([.alert, .badge, .sound])
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == "UPDATE_NOTIFICATION_IDENTIFIER" {
            DispatchQueue.main.async {
                guard let appUrl = URL(string: AppConfiguration.shared.appStoreWebUrl) else {
                    return
                }
                UIApplication.shared.open(appUrl, options: [:], completionHandler: nil)
            }
        }

        completionHandler()
    }
}

extension NotificationService.AuthorizationStatus {
    init(_ authorization: UNAuthorizationStatus) {
        switch authorization {
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .authorized:
            self = .authorized
        case .provisional:
            self = .provisional
        @unknown default:
            Logger.warning("Unknown authorization status: \(authorization)", tag: .tag)
            self = .denied
        }
    }
}
