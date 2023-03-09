use_frameworks!
platform :ios, '12.0'

secrets = ["RIAM_CONFIG_URL", "RIAM_APP_SUBSCRIPTION_KEY"]

project 'RInAppMessaging', 'UITests' => :debug

target 'RInAppMessaging_Example' do
  pod 'RInAppMessaging', :path => '.'
  pod 'SwiftLint', '~> 0.48.0' # Version 0.49+ requires macOS 12 and Swift 5.6
  pod 'RSDKUtils', '~> 4.0', :testspecs => ['Nimble', 'TestHelpers']
  pod 'Shock', '~> 6.1.2'

  abstract_target 'Tests-Common' do
    pod 'Quick', '~> 5.0'
    pod 'Nimble'

    target 'Tests'

    target 'UITests' do
      pod 'Shock', '~> 6.1.2'
    end

    target 'IntegrationTests'
  end
end

post_install do |installer|
  system("./configure-secrets.sh InAppMessaging #{secrets.join(" ")}")
  installer.pods_project.targets.each do |target|
    if target.name == 'RInAppMessaging'
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_TESTABILITY'] = 'YES'
      end
    end
  end
end
