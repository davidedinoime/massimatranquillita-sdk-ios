Pod::Spec.new do |s|
  s.name         = 'MassimaTranquillitaSDK'
  s.version      = '1.0.3'
  s.summary      = 'SDK per blocco chiamate e call screening iOS'
  s.description  = 'SDK Swift per CallKit, Call Directory Extension e WebView.'
  s.homepage     = 'https://github.com/davidedinoime/massimatranquillita-sdk-ios'
  s.license      = { :type => 'MIT' }
  s.author       = { 'Davide Dinoi' => 'davide.dinoi@massimaenergia.it' }
  s.platform     = :ios, '13.0'
  s.swift_version = '5.9'
  s.requires_arc  = true

  s.source = { :git => 'https://github.com/davidedinoime/massimatranquillita-sdk-ios.git', :tag => s.version.to_s }

  # 👉 Pod principale per l’app (include anche il widget)
  s.source_files = 'Sources/**/*.swift'
  s.resources = 'Resources/**/*.html'

  # 👉 Subspec solo per la Call Directory Extension
  s.subspec 'CallDirectoryExtension' do |ext|
    ext.source_files = 'MassimaTranquillitaExtension/CallDirectoryHandler.swift'
    ext.preserve_paths = 'MassimaTranquillitaExtension/Info.plist'
  end

  s.subspec 'Extension' do |ss|
    ss.source_files = 'Sources/MassimaTranquillitaSDK.swift'
    # Niente UIKit, niente WebView
  end
end
