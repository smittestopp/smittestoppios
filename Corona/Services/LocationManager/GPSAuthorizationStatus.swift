import CoreLocation
import Foundation

enum GPSAuthorizationStatus {
    case notDetermined
    case denied
    case restricted
    case enabledAlways
    case enabledWhenInUse
}

struct GPSState {
    let authorizationStatus: GPSAuthorizationStatus
    let isLocationServiceEnabled: Bool

    /// Simplified binary on/off state.
    ///
    /// Return true when the the state of location manager fully satisfies app requirements e.g. Always
    var isEnabled: Bool {
        guard isLocationServiceEnabled else {
            return false
        }

        switch authorizationStatus {
        case .enabledAlways:
            return true
        case .enabledWhenInUse:
            // we need access to location while the app is in background
            return false
        case .denied, .notDetermined, .restricted:
            return false
        }
    }

    /// Returns true if we've already asked for location permission and got a clear answer from the user.
    /// Useful to determine the state of authorization in Onboarding.
    var isDetermined: Bool {
        switch authorizationStatus {
        case .notDetermined:
            return false
        case .denied, .enabledAlways, .enabledWhenInUse, .restricted:
            return true
        }
    }
}

extension GPSAuthorizationStatus {
    init(_ authorizationStatus: CLAuthorizationStatus) {
        switch authorizationStatus {
        case .authorizedAlways:
            self = .enabledAlways
        case .authorizedWhenInUse:
            self = .enabledWhenInUse
        case .denied:
            self = .denied
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        @unknown default:
            Logger.warning("Unknown status: \(authorizationStatus)", tag: "GPSAuthorizationStatus")
            self = .denied
        }
    }
}
