import Foundation

struct IoTHubConnectionInfo {
    let deviceId: String
    let deviceKey: String
    let hostName: String

    init?(_ connectionString: String) {
        var maybeDeviceId: String?
        var maybeDeviceKey: String?
        var maybeHostName: String?

        for kv in connectionString.split(separator: ";") {
            let kvArray = kv.split(separator: "=", maxSplits: 1)
            if kvArray.count == 2 {
                let key = String(kvArray[0])
                let value = String(kvArray[1])
                switch key {
                case "HostName":
                    maybeHostName = value
                case "SharedAccessKey":
                    maybeDeviceKey = value
                case "DeviceId":
                    maybeDeviceId = value
                default:
                    break
                }
            }
        }

        guard
            let deviceId = maybeDeviceId,
            let deviceKey = maybeDeviceKey,
            let hostName = maybeHostName
        else {
            return nil
        }

        self.deviceId = deviceId
        self.deviceKey = deviceKey
        self.hostName = hostName
    }
}
