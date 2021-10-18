Pod::Spec.new do |s|
  s.name             = 'RInAppMessaging'
  s.version          = '5.0.0'
  s.summary          = 'Rakuten module to manage and display in-app messages'
  s.homepage         = 'https://github.com/rakutentech/ios-inappmessaging'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = 'Rakuten Ecosystem Mobile'
  s.source           = { :git => "https://github.com/rakutentech/ios-inappmessaging.git", :tag => s.version.to_s }  
  s.ios.deployment_target = '12.0'
  s.swift_versions = ['5.1', '5.2', '5.3', '5.4', '5.5']

  s.source_files = 'RInAppMessaging/Classes/**/*.{swift,h,m}'
  s.resource_bundles = { 'RInAppMessagingAssets' => ['RInAppMessaging/Assets/*'] }
end
