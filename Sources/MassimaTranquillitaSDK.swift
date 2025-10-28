//
//  MassimaTranquillitaSDK.swift
//  MassimaTranquillitaSDK
//
//  Created by Davide Dinoi on 17/10/25.
//
import UIKit
import CallKit

public class MassimaTranquillitaSDK {
    
    public static let EXTENSION_ID = "it.massimatranquillitatest.sdk.CallDirectoryExtension"
    
    private static var observer: NSObjectProtocol?
    
    // MARK: - Inizializzazione SDK
    public static func initialize() {
        print("MassimaTranquillitaSDK inizializzato ✅")
    }
    
    // MARK: - Impostazioni generali
    func openSettings(resolve: @escaping (Bool) -> Void, reject: @escaping (String, String, Error?) -> Void) {
        if #available(iOS 13.4, *) {
            CXCallDirectoryManager.sharedInstance.openSettings { error in
                if let error = error {
                    print("[BlockList] Errore aprendo le impostazioni: \(error.localizedDescription)")
                    reject("openSettings", "Failed to open settings", error)
                } else {
                    print("[BlockList] Impostazioni aperte correttamente")
                    resolve(true)
                }
            }
        } else {
            print("[BlockList] Open settings non supportato su questa versione iOS")
            reject("open_settings_error", "Open settings not supported on this iOS version", nil)
        }
    }
    
    /// Controlla se l’estensione Call Directory è attiva
    public static func isCallScreeningRoleActive(completion: @escaping (Bool) -> Void) {
#if targetEnvironment(simulator)
        DispatchQueue.main.async { completion(false) }
        return
#endif
        let extensionID = EXTENSION_ID
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionID) { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Errore recuperando stato: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                completion(status == .enabled)
            }
        }
    }
    
    
    public static func requestCallScreeningRole(
        from viewController: UIViewController,
        completion: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(
            title: "Attiva blocco chiamate",
            message: "Per abilitare il blocco chiamate, attiva l’estensione Massima Tranquillità nelle Impostazioni di iOS.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel) { _ in
            completion(false)
        })
        
        alert.addAction(UIAlertAction(title: "Apri Impostazioni", style: .default) { _ in
            // Chiudo l'alert prima di effettuare la chiamata a Settings
            viewController.dismiss(animated: true) {
                DispatchQueue.main.async {
                    if #available(iOS 13.4, *) {
                        CXCallDirectoryManager.sharedInstance.openSettings { error in
                            if let error = error {
                                print("❌ Errore aprendo impostazioni blocco chiamate: \(error.localizedDescription)")
                            } else {
                                print("✅ Impostazioni aperte correttamente")
                            }
                        }
                    } else {
                        print("⚠️ Funzione non supportata su questa versione iOS")
                    }
                }
            }
            completion(true)
        })
        
        viewController.present(alert, animated: true)
    }
    
    public static func openServiceUI(from viewController: UIViewController, url: String) {
        guard let link = URL(string: url) else { return }
        let webVC = CallBlockerWebViewController()
        webVC.loadURL(link)
        viewController.present(webVC, animated: true)
    }
    
    // MARK: - Blocca numeri
    public static func blockNumber(_ number: String) {
        print("Numero bloccato: \(number)")
    }
}
