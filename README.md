# Corona: movement tracking app for iOS

## General information

The app supports iOS 12.0+, as this covers 96.2% of iPhones according to [iOS version trends](https://mixpanel.com/trends/#report/ios_13).

Reference for Location data in the background: [Apple Docs: Handling location events in the background](https://developer.apple.com/documentation/corelocation/getting_the_user_s_location/handling_location_events_in_the_background).

These relevant services exist for location data:

* Standard location service: For highly accurate Location updates while the app is in the foreground/background
* Significant-change location service: Can run even when the app has been terminated. Only significant updates, when the device has moved 500 meters or so. When using a simulator on a "city run", it equates to a location update every 3 minutes.
* Visits service: Includes different data from the two previous services. Monitors visits instead of location. Specifically, it reports when the device has left a place where it has been stationary for some time. The reported information includes coordinates as well as arrival and departure times.
However, according to [a comment on stackoverflow](https://stackoverflow.com/questions/29441137/cllocationmanager-startmonitoringvisits-is-not-working-in-simulator#comment47560734_29441137), the callbacks can be delayed by several hours.
* Region monitoring (geofencing): Allows you to define up to 20 regions for monitoring. The regions have a center and a radius. If the device exits or enters the region, the app callback will be invoked. The callback will only be invoked if the device persists on the same side of the boundary for [20 seconds](https://developer.apple.com/documentation/corelocation/monitoring_the_user_s_proximity_to_geographic_regions). Initial research indicates that the minimum radius is 100m.

## Building

Dependencies are managed by [Carthage](https://github.com/Carthage/Carthage) and [CocoaPods](https://cocoapods.org/), and are defined in `Cartfile` and `Podfile` respectively.

To install Carthage dependencies and prepare the project to be built run `carthage build`. The code for CocoaPods dependencies is added to the git repo, so there is no need to run extra commands.

Remember to open the Xcode workspace instead of the Xcode project file: `open Corona.xcworkspace`.

For building and running tests on the CI we use [fastlane](https://fastlane.tools).

## Running tests

The project is configured with two test plans `CoronaTests` (unit tests and UI tests) and `CoronaSnapshotTests` (snapshot/screenshot tests). The snapshot tests are running under multiple locales to ensure localization works as expected with different font sizes.

Tests can be run from Xcode itself or by running `fastlane testall` command.

## CI

Steps to deploy a build by CI:

#### scripts/addkey.sh

Installs the private key used for distribution signing to the CI machine and copies the provisioning profile to the correct folder

#### scripts/travis.sh

- Decides if we want to build and deploy a build depending if we are a pull request or not
- Sets the git remote URL to be able to make a commit and increment the build number
- Runs fastlane dev_build action

#### fastlane dev_build

- Generates the changelog by combining CHANGELOG.md and the latest PR commits since the last released tag
- Increments the build number in the project and Info.plist s
- Commits and pushes those changes 
- builds Corona Release (dev)
- uploads to test flight with release notes and invites testers 

### Builds being deployed by fastlane require a few parameters:

- GIT_TOKEN is a personal access token from github, so that fastlane can increment the build number and commit the bump for the next build. Otherwise Apple will reject the build.
- upload_to_testflight fastlane action username parameter set to an account with access to the app
- FASTLANE_PASSWORD is the password for the apple id
- FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD is an apple id app specific password generated at appleid.apple.com for testflight upload
- KEY_PASSWORD is the password to unlock the .p12 private key used for signing the app 
- FASTLANE_SESSION is a temporary session valid for one month in other to get around apple's 2FA, generated with fastlane spaceauth -u ...