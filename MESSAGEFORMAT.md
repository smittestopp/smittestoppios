# IoTHub Message Format

## Telemetry event

Each IoTHub telemetry message sent from the app to the cloud includes the following fields:

- `appVersion`: `String` version of the app as seen on App Store.
- `model`: `String` phone model. To convert to a recognizable model, see [this](https://stackoverflow.com/a/26962452).
- `events`: `[EventData]` a list of either GPS or Bluetooth events, but never a mix of both. See below for more info.
- `platform`: `String` the value will always be `ios` for the iOS app.
- `osVersion`: `String` iOS version running on the device.
- `jailbroken`: `Bool` set to `true` if the app determined that the device is jailbroken.

`EventData` is either GPS data or BLE data as described below.

#### GPS Data

`eventType` message attribute is set to `gps`.

The payload has the following fields:

- `timeFrom`: `String` ISO 8601 formatted date. The event details are valid from this timepoint.
- `timeTo`: `String` ISO 8601 formatted date. The event details are valid until this timepoint.
- `latitude`: `Double` the location latitude.
- `longitude`: `Double` the location longitude.
- `accuracy`: `Double` the radius of uncertainty for the location, measured in meters.
- `speed`: `Double` the instantaneous speed of the device, measured in meters per second. A negative value means invalid speed.
- `altitude`: `Double` the location altitude. The unit is meters.
- `altitudeAccuracy`: `Double` the accuracy of the altitude value, measured in meters. A negative number means that `altitude` is invalid.


Example:

```json
{
  "appVersion": "1.1.0",
  "model": "iPhone10,5",
  "events": [
    {
      "timeFrom": "2020-04-30T12:38:30Z",
      "timeTo": "2020-04-30T12:38:30Z",
      "latitude": 61.93372532454498,
      "longitude": 10.728583389659596,
      "accuracy": 65.0,
      "speed": 2.10,
      "altitude": 71.1960678100586,
      "altitudeAccuracy": 10.0
    }
  ],
  "platform": "ios",
  "osVersion": "13.4.1",
  "jailbroken": false
}
```

#### BLE Data

`eventType` message attribute is set to `bluetooth`.

The payload has the following fields:

- `time`: `String` ISO 8601 formatted date. The time when the RSSI reading was acquired.
- `deviceId`: `String` the device identifier given by the other device.
- `rssi`: `Int` the RSSI value.
- `txPower`: `Int` the txPower advertised by the other device. This field is omitted if the value is unavailable.
- `location`: `Location` sub-object containing last known GPS location. Optional. `null` if there is no known location.

`Location` contains the following fields:
- `latitude`: `Double` the location latitude.
- `longitude`: `Double` the location longitude.
- `accuracy`: `Double` the radius of uncertainty for the location, measured in meters.
- `timestamp`: `String` ISO 8601 formatted date. The time for the last known location.


```json
{
  "appVersion": "1.1.0",
  "model": "iPhone10,5",
  "events": [
    {
      "deviceId": "123456789abcd123456789abcd123456",
      "rssi": -90,
      "txPower": 12,
      "time": "2020-04-30T12:38:30Z",
      "location": {
        "latitude": 61.93372532454498,
        "longitude": 10.728583389659596,
        "accuracy": 65.0,
        "timestamp": "2020-04-30T12:35:30Z"
      }
    }
  ],
  "platform": "ios",
  "osVersion": "13.4.1",
  "jailbroken": false
}
```

#### Heartbeat

`eventType` message attribute is set to `sync`.

The payload has the following fields:

- `timestamp`: `String` ISO 8601 formatted date.
- `state`: (0 both GPS and BT are running, 1 only GPS is running, 2 Only BT is running, 3 both are disabled)

```json
{
  "appVersion": "1.1.0",
  "model": "iPhone10,5",
  "events": [
    {
      "timestamp": "2020-04-30T12:38:30Z",
      "state": 0
    }
  ],
  "platform": "ios",
  "osVersion": "13.4.1",
  "jailbroken": false
}
```
