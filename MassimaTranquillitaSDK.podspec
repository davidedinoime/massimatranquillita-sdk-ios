Pod::Spec.new do |s|
  s.name             = 'MassimaTranquillitaSDK'
    s.version          = begin
    require 'plist'
    info = Plist.parse_xml("MassimaTranquillitaSDK/Info.plist")
    info["CFBundleShortVersionString"]
  end
  s.summary          = 'SDK per blocco chiamate e call screening iOS'
  s.description      = <<-DESC
MassimaTranquillitaSDK fornisce un framework Swift con helper per CallKit, Call Directory Extension e WebView di gestione numeri bloccati. Supporta integrazione nativa, React Native e Flutter.
  DESC
  s.homepage         = 'https://github.com/davidedinoime/massimatranquillita-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Davide Dinoi' => 'davide.dinoi@massimaenergia.it' }
  s.platform         = :ios, '13.0'

  # MARK: - Framework principale
  s.source           = { :git => 'https://github.com/davidedinoime/massimatranquillita-sdk-ios.git', :tag => s.version.to_s }

  s.source_files     = 'Sources/MassimaTranquillitaSDK/**/*.{swift,h,m}'
  s.resources        = 'Sources/MassimaTranquillitaSDK/**/*.html'

  s.swift_version    = '5.0'

  # MARK: - Dipendenze
  # s.dependency 'SomeOtherPod', '~> 1.2'

  # MARK: - Call Directory Extension
  s.subspec 'CallDirectoryExtension' do |ext|
    ext.source_files  = 'Sources/CallDirectoryExtension/**/*.{swift,h,m}'
    ext.resources     = 'Sources/CallDirectoryExtension/**/*.plist'
    ext.platform      = :ios, '13.0'
    ext.swift_version = '5.0'
  end

  # MARK: - Configurazione linker / module
  s.requires_arc = true
end
