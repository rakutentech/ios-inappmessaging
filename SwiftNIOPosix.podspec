Pod::Spec.new do |s|
  s.name = 'SwiftNIOPosix'
  s.version = '2.38.0'
  s.license = { :type => 'Apache 2.0', :file => 'LICENSE.txt' }
  s.summary = 'Event-driven network application framework for high performance protocol servers & clients, non-blocking.'
  s.homepage = 'https://github.com/apple/swift-nio'
  s.author = 'Apple Inc.'
  s.source = { :git => 'https://github.com/apple/swift-nio.git', :tag => s.version.to_s }
  s.documentation_url = 'https://apple.github.io/swift-nio/docs/current/NIO/index.html'
  s.module_name = 'NIOPosix'

  s.swift_version = '5.4'
  s.cocoapods_version = '>=1.6.0'
  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '6.0'

  s.source_files = 'Sources/NIOPosix/**/*.{swift,c,h}'
  
  s.dependency 'CNIODarwin', s.version.to_s 
  s.dependency 'CNIOLinux', s.version.to_s 
  s.dependency '_NIODataStructures', s.version.to_s 
  s.dependency 'CNIOWindows', s.version.to_s 
  s.dependency 'CNIOAtomics', s.version.to_s 
  s.dependency 'SwiftNIOCore', s.version.to_s 
  s.dependency 'SwiftNIOConcurrencyHelpers', s.version.to_s
  
  
end
