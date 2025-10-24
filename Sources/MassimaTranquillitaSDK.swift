//
//  MassimaTranquillitaSDK.swift
//  MassimaTranquillitaSDK
//
//  Created by Davide Dinoi on 17/10/25.
//
import UIKit
import CallKit

public class MassimaTranquillitaSDK {
    
    public static let EXTENSION_ID = "com.massimatranquillita.CallDirectoryExtension"

    // MARK: - Inizializzazione SDK
    public static func initialize() {
        print("MassimaTranquillitaSDK inizializzato ✅")
    }
    
    func loadCallersFromAppGroup() -> [Caller] {
        guard let userDefaults = UserDefaults(suiteName: APP_GROUP),
              let savedArray = userDefaults.array(forKey: DATA_KEY) as? [[String: Any]] else {
            print("[SDK] Nessun caller trovato")
            return []
        }
        return savedArray.map { Caller(dictionary: $0) }
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

    // MARK: - Call Screening
    public static func isCallScreeningRoleActive(completion: @escaping (Bool) -> Void) {
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: EXTENSION_ID) { status, error in
            if let error = error {
                #if targetEnvironment(simulator)
                completion(false)
                #else
                print("[MassimaTranquillitaSDK] Errore getEnabledStatus: \(error.localizedDescription)")
                completion(false)
                #endif
                return
            }
            completion(status == .enabled)
        }
    }

    public static func requestCallScreeningRole(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Attiva blocco chiamate",
            message: "Per abilitare il blocco chiamate, attiva l'estensione Massima Tranquillità nelle impostazioni di iOS.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel) { _ in
            completion(false)
        })

        alert.addAction(UIAlertAction(title: "Apri Impostazioni", style: .default) { _ in
            if #available(iOS 13.4, *) {
                // 🔹 Metodo nativo per aprire direttamente la sezione “Blocco chiamate e identificazione”
                CXCallDirectoryManager.sharedInstance.openSettings { error in
                    if let error = error {
                        print("❌ Errore aprendo impostazioni blocco chiamate: \(error.localizedDescription)")
                    }
                }
            }
            completion(true)
        })

        viewController.present(alert, animated: true)
    }

    // MARK: - Blocca numeri
    public static func blockNumber(_ number: String) {
        print("Numero bloccato: \(number)")
    }
}
