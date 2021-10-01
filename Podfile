use_frameworks!
platform :ios, '11.0'

secrets = ["RIAM_CONFIG_URL", "RIAM_APP_SUBSCRIPTION_KEY"]

target 'RInAppMessaging_Example' do
  pod 'RInAppMessaging', :path => '.'
  pod 'SwiftLint', '~> 0.42'

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
