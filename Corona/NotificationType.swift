import UIKit

enum NotificationType {}

extension NotificationType {
    // MARK: LocalStorage

    static let TrackingConsentUpdated = Notification.Name("TrackingConsentUpdated")

    // MARK: LocationManager

    static let GPSStateUpdated = Notification.Name("GPSStateUpdated")
    static let BluetoothStateUpdated = Notification.Name("BluetoothStateUpdated")

    // MARK: LoginService

    static let TokenExpired = Notification.Name("LoginService.TokenExpired")
    static let DeviceProvisioned = Notification.Name("LoginService.DeviceProvisioned")
}
