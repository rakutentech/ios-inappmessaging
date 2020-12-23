Pod::Spec.new do |s|
  s.name             = 'RInAppMessaging'
  s.version          = '2.1.0'
  s.summary          = 'Rakuten module to manage and display in-app messages'
  s.homepage         = 'https://github.com/rakutentech/ios-inappmessaging'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = 'Rakuten Ecosystem Mobile'
  s.source           = { :git => "https://github.com/rakutentech/ios-inappmessaging.git", :tag => s.version.to_s }  
  s.ios.deployment_target = '10.0'
  s.swift_version = '5.1'

  s.source_files = 'RInAppMessaging/Classes/**/*.{swift,h,m}'
  s.resource_bundles = { 'RInAppMessagingAssets' => ['RInAppMessaging/Assets/*'] }
end
