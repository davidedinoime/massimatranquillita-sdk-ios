//
//  MassimaTranquillitaSDK.swift
//  MassimaTranquillitaSDK
//
//  Created by Davide Dinoi on 17/10/25.
//
import UIKit
import CallKit

public class MassimaTranquillitaSDK {

    // ✅ Estensione ID configurabile
    private static var extensionID: String?
    
    public static var currentExtensionID: String? {
        return extensionID
    }

    // MARK: - Inizializzazione SDK
    public static func initialize(withExtensionID id: String) {
        self.extensionID = id
        print("MassimaTranquillitaSDK inizializzato con EXTENSION_ID: \(id) ✅")
    }

    // MARK: - Call Screening
    public static func isCallScreeningRoleActive(completion: @escaping (Bool) -> Void) {
#if targetEnvironment(simulator)
        DispatchQueue.main.async { completion(false) }
        return
#endif
        guard let extensionID = extensionID else {
            print("❌ EXTENSION_ID non inizializzato. Chiama MassimaTranquillitaSDK.initialize(withExtensionID:)")
            completion(false)
            return
        }

        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionID) { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[MassimaTranquillitaSDK] Errore getEnabledStatus per '\(extensionID)': \(error.localizedDescription)")
                    completion(false)
                    return
                }

                switch status {
                case .enabled:
                    completion(true)
                case .disabled, .unknown:
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }

    public static func requestCallScreeningRole(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let extensionID = extensionID else {
            print("❌ EXTENSION_ID non inizializzato. Chiama MassimaTranquillitaSDK.initialize(withExtensionID:)")
            completion(false)
            return
        }

        let alert = UIAlertController(
            title: "Attiva blocco chiamate",
            message: "Per abilitare il blocco chiamate, attiva l’estensione Massima Tranquillità nelle Impostazioni di iOS.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel) { _ in
            completion(false)
        })

        alert.addAction(UIAlertAction(title: "Apri Impostazioni", style: .default) { _ in
            viewController.dismiss(animated: true) {
                if #available(iOS 13.4, *) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        CXCallDirectoryManager.sharedInstance.openSettings { error in
                            if let error = error {
                                print("❌ Errore aprendo impostazioni: \(error.localizedDescription)")
                            } else {
                                print("✅ Impostazioni aperte correttamente")
                            }
                        }
                    }

                    var observer: NSObjectProtocol?
                    observer = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                                                      object: nil,
                                                                      queue: .main) { _ in
                        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionID) { status, error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    print("❌ Errore recuperando stato: \(error.localizedDescription)")
                                    completion(false)
                                } else {
                                    completion(status == .enabled)
                                }

                                if let obs = observer {
                                    NotificationCenter.default.removeObserver(obs)
                                }
                            }
                        }
                    }
                } else {
                    print("⚠️ Funzione non supportata su questa versione iOS")
                    completion(false)
                }
            }
        })

        viewController.present(alert, animated: true)
    }

    public static func openServiceUI(from viewController: UIViewController, url: String) {
        guard let link = URL(string: url) else { return }
        let webVC = CallBlockerWebViewController()
        webVC.loadURL(link)
        viewController.present(webVC, animated: true)
    }

    public static func blockNumber(_ number: String) {
        print("Numero bloccato: \(number)")
    }
}
