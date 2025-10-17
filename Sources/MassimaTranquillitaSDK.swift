//
//  MassimaTranquillitaSDK.swift
//  MassimaTranquillitaSDK
//
//  Created by Davide Dinoi on 17/10/25.
//
import UIKit
import CallKit

public class MassimaTranquillitaSDK {
    
    public static let EXTENSION_ID = "io.massimatranquillita.CallDirectoryExtension"

    // MARK: - Inizializzazione SDK
    public static func initialize() {
        print("MassimaTranquillitaSDK inizializzato ✅")
    }

    // MARK: - Impostazioni generali
    public static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
            message: "Per abilitare il blocco chiamate, devi attivare l'estensione Massima Tranquillità nelle impostazioni di iOS.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel) { _ in completion(false) })
        alert.addAction(UIAlertAction(title: "Apri Impostazioni", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
