# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'Corona' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Corona
  pod 'Alamofire', '~> 5.0'
  pod 'SQLCipher', '~>4.2.0'
  pod 'SQLite.swift/SQLCipher', '~> 0.12.0'
  pod 'AppCenter'

  pod 'AzureIoTUtility', '=1.3.8a'
  pod 'AzureIoTuMqtt', '=1.3.8a'
  pod 'AzureIoTuAmqp', '=1.3.8a'
  pod 'AzureIoTHubClient',
    :git => 'git@github.com:simula/azure-iot-sdk-c.git',
    :tag => "1.3.8a-simula"

  pod 'JWTDecode', '~> 2.4'
  pod 'KeychainAccess', '=4.1.0'
  pod 'SwiftFormat/CLI'
  pod 'CryptoSwift', '~> 1.0'

  target 'CoronaTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'CoronaSnapshotTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'SnapshotTesting', '~> 1.7.2'
  end

  target 'CoronaUITests' do
    # Pods for testing
  end

end

# Copy latest acknowledgements to Settings bundle
post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-Corona/Pods-Corona-acknowledgements.plist', 'Resources/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
