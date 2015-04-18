Pod::Spec.new do |s|
  s.name             = "MKStoreKit"
  s.version          = "6.0.0"
  s.summary          = "An in-App Purchase framework for iOS 7.0+."
  s.description      = <<-DESC
                        An in-App Purchase framework for iOS 7.0+.
                        MKStoreKit makes in-App Purchasing super simple by remembering your purchases,
                        validating reciepts, and tracking virtual currencies (consumable purchases).
                        Additionally, it keeps track of auto-renewable subscriptions and their expirationd dates.
                        It couldn't be easier!
                        DESC
  s.homepage         = "https://github.com/MugunthKumar/MKStoreKit"
  s.license          = 'MIT'
  s.author           = { "Mugunth Kumar" => "mugunth@steinlogic.com" }
  s.source           = { :git => "https://github.com/MugunthKumar/MKStoreKit.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'Pod/Classes/**/*'
  s.frameworks = 'StoreKit'
end
