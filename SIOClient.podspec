Pod::Spec.new do |s|
  s.name         = 'SIOClient'
  s.version      = '0.1.2'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.summary      = 'A Socket.io client library written in Objective-C for the iOS and Mac OS X platforms.'
  s.homepage     = 'https://github.com/woodnathan/SIOClient/'
  s.author       = { 'Nathan Wood' => 'nathan@appening.com.au' }
  s.source       = { :git => 'https://github.com/woodnathan/SIOClient.git', :tag => "v#{s.version}" }
  
  s.source_files = 'SIOClient'
  s.requires_arc = true
  s.ios.deployment_target = '5.0' # NSJSONSerialization
  s.osx.deployment_target = '10.7' # NSJSONSerialization
  
  s.dependency 'SocketRocket'
end
