use_frameworks!
platform :ios, '12.0'

# Variable necessary to parse Shock podspec file from their master branch
ENV['LIB_VERSION'] = '6.1.1'
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
      # The currently released Shock version relies on swift-nio version (2.38) which has following issue:
      # https://github.com/apple/swift-nio/issues/2073
      # The issue has been fixed in SwiftNIO version 2.40
      # Until a new version of Shock is released, the pod declaration should point to master branch which contains updated SwiftNIO dependency
      # (Older versions of Shock cannot be used with Xcode 13.3)'
      pod 'Shock', :git => 'https://github.com/justeat/Shock'
    end

    target 'IntegrationTests'
  end
end

post_install do |installer|
  system("./configure-secrets.sh InAppMessaging #{secrets.join(" ")}")
end
