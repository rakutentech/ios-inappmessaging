use_frameworks!
inhibit_all_warnings!
platform :ios, '12.0'

secrets = ["RIAM_CONFIG_URL", "RIAM_APP_SUBSCRIPTION_KEY"]

target 'RInAppMessaging_Example' do
  pod 'RInAppMessaging', :path => '.', :inhibit_warnings => false
  pod 'SwiftLint', '~> 0.42'
  pod 'RSDKUtils', '~> 2.1', :testspecs => ['Nimble', 'TestHelpers']
  pod 'Shock', '~> 6.0'

  abstract_target 'Tests-Common' do
    pod 'Quick'
    pod 'Nimble'

    target 'Tests' do
    end

    target 'UITests' do
      pod 'Shock', '~> 6.0'
    end

    target 'IntegrationTests' do
    end
  end
end

post_install do |installer|
  system("./configure-secrets.sh InAppMessaging #{secrets.join(" ")}")
end
