Pod::Spec.new do |s|
  s.name               = "MKStoreKit"
  s.version            = '6.0-beta1'
  s.summary            = 'An in-App Purchase framework for iOS 7.0+.'
  s.homepage           = 'https://github.com/MugunthKumar/MKStoreKit'
  s.authors            = 'Mugunth Kumar'
  s.license            = 'MIT License'
  s.source             = { :git => 'https://github.com/MugunthKumar/MKStoreKit.git', :commit => '08eac410eca89edb2cddef453b2afa71e10b2370' }
  s.source_files       = 'MKStoreKit/MKStoreKit.h'
  s.requires_arc       = true
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.10'
end