Pod::Spec.new do |s|
  s.name             = 'RInAppMessaging'
  s.version          = '9.2.0-snapshot'
  s.summary          = 'Rakuten module to manage and display in-app messages'
  s.homepage         = 'https://github.com/rakutentech/ios-inappmessaging'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = 'Rakuten Ecosystem Mobile'
  s.source           = { :git => "https://github.com/rakutentech/ios-inappmessaging.git", :tag => s.version.to_s }  
  s.ios.deployment_target = '14.0'
  s.swift_versions = ['5.7.1']
  s.resources = ['Sources/RInAppMessaging/Resources/PrivacyInfo.xcprivacy']
  s.dependency 'RSDKUtils', '~> 5.1.0'
  s.dependency 'RSDKUtils/REventLogger'
  s.source_files = 'Sources/RInAppMessaging/**/*.swift'
  s.resource_bundles = { 'RInAppMessagingResources' => ['Sources/RInAppMessaging/Resources/*'] }
end
