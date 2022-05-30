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

    target 'IntegrationTests'
  end
end

post_install do |installer|
  system("./configure-secrets.sh InAppMessaging #{secrets.join(" ")}")
end
