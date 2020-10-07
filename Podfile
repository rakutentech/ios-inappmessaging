use_frameworks!
platform :ios, '10.0'

target 'RInAppMessaging_Example' do
  pod 'RInAppMessaging', :path => '.'
  pod 'SwiftLint', '~> 0.40.0'

  target 'Tests' do
    pod 'RInAppMessaging', :path => '.'
    pod 'Quick'
    pod 'Nimble'
  end
end

post_install do |installer|
  system("./configure-secrets.sh")
end
