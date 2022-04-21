use_frameworks!
platform :ios, '12.0'

secrets = ["RIAM_CONFIG_URL", "RIAM_APP_SUBSCRIPTION_KEY"]

target 'RInAppMessaging_Example' do
  pod 'RInAppMessaging', :path => '.'
  pod 'SwiftLint', '~> 0.42'
  pod 'RSDKUtils', '~> 3.0.0', :testspecs => ['Nimble', 'TestHelpers']

  abstract_target 'Tests-Common' do
    pod 'Quick', '~> 5.0'
    pod 'Nimble'

    target 'Tests'

    target 'UITests' do
      # Shock 6.1 currently relies on swift-nio version (2.38) which has following issue:
      # https://github.com/apple/swift-nio/issues/2073
      # The issue has been fixed in https://github.com/apple/swift-nio/pull/2082
      # The fixed script has been used to generate custom SwiftNIOPosix podspec as a workaround
      # This workaround can probably be removed after the next SwiftNIO release
      # (Older versions of Shock cannot be used with Xcode 13.3)
      pod 'SwiftNIOPosix', :podspec => './SwiftNIOPosix.podspec'
      pod 'Shock', '~> 6.1.0'
    end

    target 'IntegrationTests'
  end
end

post_install do |installer|
  system("./configure-secrets.sh InAppMessaging #{secrets.join(" ")}")
end
