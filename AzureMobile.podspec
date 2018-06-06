Pod::Spec.new do |s|

  s.name          = 'AzureMobile'
  s.version       = '0.1.3'
  s.summary       = 'Microsoft Azure client SDK for iOS.'

  s.description   = 'Microsoft Azure client SDK for iOS, macOS, watchOS, tvOS.'

  s.homepage      = 'https://github.com/Azure/Azure.Mobile'
  s.license       = { :type => 'MIT', :file => 'LICENSE' }
  s.author        = 'Microsoft Azure'

  s.source        = { :git => 'https://github.com/Azure/Azure.Mobile.git', :tag => "v#{s.version}" }

  s.swift_version = '4.1'

  s.dependency 'AzureData', '0.1.3'

  s.source_files = 'iOS/AzureMobile/Source/*.{swift,h,m}'

  s.ios.deployment_target     = '10.0'
  s.osx.deployment_target     = '10.12'
  s.tvos.deployment_target    = '10.0'
  s.watchos.deployment_target = '3.0'
  
end