Pod::Spec.new do |s|
  s.name         = 'MassimaTranquillitaSDK'
  s.version      = '1.0.1'
  s.summary      = 'SDK per blocco chiamate e call screening iOS'
  s.description  = 'MassimaTranquillitaSDK fornisce un framework Swift con helper per CallKit, Call Directory Extension e WebView.'
  s.homepage     = 'https://github.com/davidedinoime/massimatranquillita-sdk-ios'
  s.license      = { :type => 'MIT' } # evita file se non esiste LICENSE
  s.author       = { 'Davide Dinoi' => 'davide.dinoi@massimaenergia.it' }
  s.platform     = :ios, '13.0'
  s.swift_version = '5.9'
  s.requires_arc  = true

  s.source = { :git => 'https://github.com/davidedinoime/massimatranquillita-sdk-ios.git', :tag => s.version.to_s }

  # Files principali Swift
  s.source_files = 'Sources/**/*.swift'

  # Risorse principali (widget HTML)
  s.resources = 'Resources/**/*.html'

  # Subspec Call Directory Extension
  s.subspec 'CallDirectoryExtension' do |ext|
    # Specifica ESATTAMENTE il file.
    ext.source_files = 'MassimaTranquillitaExtension/CallDirectoryHandler.swift'
    
    # Rimuovi l'ereditarietà di tutti i file dal pod principale
    ext.preserve_paths = 'MassimaTranquillitaExtension/Info.plist'
    
    # Rimuovi le dipendenze del pod principale (se ne avessi)
    # ext.dependency 'MassimaTranquillitaSDK/Core' # Esempio, non applicabile qui.
end
end
