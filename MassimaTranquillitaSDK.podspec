Pod::Spec.new do |s|
  s.name         = 'MassimaTranquillitaSDK'
  s.version      = '1.0.1'
  s.summary      = 'SDK per blocco chiamate e call screening iOS'
  s.description  = 'MassimaTranquillitaSDK fornisce un framework Swift con helper per CallKit, Call Directory Extension e WebView.'
  s.homepage     = 'https://github.com/davidedinoime/massimatranquillita-sdk-ios'
  s.license      = { :type => 'MIT' }
  s.author       = { 'Davide Dinoi' => 'davide.dinoi@massimaenergia.it' }
  s.platform     = :ios, '13.0'
  s.swift_version = '5.9'
  s.requires_arc  = true

  s.source = { :git => 'https://github.com/davidedinoime/massimatranquillita-sdk-ios.git', :tag => s.version.to_s }

  # File principali Swift
  s.source_files = 'Sources/**/*.swift'

  # Risorse principali
  s.resources = 'Resources/**/*.{plist,html}'

  # Subspec Call Directory Extension
  s.subspec 'CallDirectoryExtension' do |ext|
    ext.source_files = 'MassimaTranquillitaExtension/**/*.swift'
  end
end
