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
      # Version 6.1 currently relies on swift-nio version (2.38) which has following issue
      # https://github.com/apple/swift-nio/issues/2073
      # Version 6.0 uses older swift-nio version which doesn't have that problem
      pod 'Shock', '~> 6.0.0'
    end

    target 'IntegrationTests'
  end
end

post_install do |installer|
  system("./configure-secrets.sh InAppMessaging #{secrets.join(" ")}")
end
