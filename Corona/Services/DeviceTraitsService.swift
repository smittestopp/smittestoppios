import UIKit

protocol DeviceTraitsServiceProviding: class {
    /// Returns true when the screen size is considered small and we need to make the UI more compact.
    var isSmall: Bool { get }
    /// Whether the current screen has a notch
    var hasNotch: Bool { get }
    /// Returns a device model name e.g. "iPhone12,3".
    /// On Simulator this returns "x86_64".
    var modelName: String { get }
    /// Returns iOS system version e.g. "13.4.1"
    var systemVersion: String { get }
    /// Returns true if we are running on a simulator
    var isSimulator: Bool { get }
    /// Returns true for jailbroken devices
    var isJailbroken: Bool { get }
}

protocol HasDeviceTraitsService {
    var deviceTraits: DeviceTraitsServiceProviding { get }
}

class DeviceTraitsService: DeviceTraitsServiceProviding {
    static let shared: DeviceTraitsService = .init()

    private init() { }

    var isSmall: Bool {
        let iPhone8ScreenHeight: CGFloat = 667
        return UIScreen.main.bounds.height < iPhone8ScreenHeight
    }

    var hasNotch: Bool {
        guard let window = UIApplication.shared.keyWindow else {
            return false
        }
        return window.safeAreaInsets.bottom  > 0
    }

    lazy var modelName: String = {
        // Inspired by https://medium.com/ios-os-x-development/get-model-info-of-ios-devices-18bc8f32c254
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        return identifier
    }()

    var systemVersion: String {
        return UIDevice.current.systemVersion
    }

    var isSimulator: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }

    var isJailbroken: Bool {
        // Inspired by https://github.com/TheSwiftyCoder/JailBreak-Detection/blob/master/JailBreak.swift

        let hasCydiaUrlScheme: (()->Bool) = {
            guard
                let cydiaUrlScheme = URL(string: "cydia://package/com.example.package")
            else {
                assertionFailure()
                return false
            }

            return UIApplication.shared.canOpenURL(cydiaUrlScheme)
        }

        let fileExists: ((String)->Bool) = { path in
            return FileManager.default.fileExists(atPath: path)
        }

        let fileWriteable: ((String)->Bool) = { path in
            do {
                try "hello".write(toFile: path, atomically: true, encoding: .utf8)
                try FileManager.default.removeItem(atPath: path)
                return true
            } catch {
                return false
            }
        }

        return hasCydiaUrlScheme()
            || fileExists("/Applications/Cydia.app")
            || fileExists("/Library/MobileSubstrate/MobileSubstrate.dylib")
            || fileExists("/bin/bash")
            || fileExists("/usr/sbin/sshd")
            || fileExists("/etc/apt")
            || fileExists("/usr/bin/ssh")
            || fileExists("/private/var/lib/apt")
            || fileWriteable("/private/test.txt")
    }
}
