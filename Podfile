use_frameworks!
platform :ios, '14.0'

secrets = ["RIAM_CONFIG_URL", "RIAM_APP_SUBSCRIPTION_KEY"]

project 'RInAppMessaging', 'UITests' => :debug

target 'RInAppMessaging_Example' do
  pod 'RInAppMessaging', :path => '.'
  pod 'SwiftLint', '~> 0.50'
  pod 'RSDKUtils', '~> 5.1.0', :testspecs => ['Nimble', 'TestHelpers']
  pod 'RSDKUtils/REventLogger'
  
  pod 'Shock', '~> 6.1.2'

  abstract_target 'Tests-Common' do
    pod 'Quick', '~> 5.0'
    pod 'Nimble','~> 12.1.0'

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
    target.build_configurations.each do |config|
      if target.name == 'RInAppMessaging'
        config.build_settings['ENABLE_TESTABILITY'] = 'YES'
      end
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_i < 9
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
      end
    end
  end
end
