import Foundation
import UIKit
import CallKit

public class MassimaTranquillitaSDK {

    public static let APP_GROUP = "group.com.massimatranquillita"
    public static let DATA_KEY = "CALLER_LIST"
    public static let EXTENSION_ID = "com.massimatranquillita.CallDirectoryExtension"

    // MARK: - Inizializzazione SDK
    public static func initialize() {
        print("[MassimaTranquillitaSDK] Inizializzato ✅")
    }

    // MARK: - Blocca numeri
    public static func blockNumber(_ number: UInt64, name: String = "") {
        var current = getCallerList()
        let newCaller = ["name": name, "numbersToAdd": [NSNumber(value: number)], "numbersToRemove": []] as [String : Any]
        current.append(newCaller)
        saveCallerList(current)
        print("[MassimaTranquillitaSDK] Numero aggiunto: \(number)")
    }

    // MARK: - Recupera numeri da bloccare (per l’estensione)
    public static func getCallerList() -> [[String: Any]] {
        guard let userDefaults = UserDefaults(suiteName: APP_GROUP),
              let savedArray = userDefaults.array(forKey: DATA_KEY) as? [[String: Any]] else {
            return []
        }
        return savedArray
    }

    private static func saveCallerList(_ array: [[String: Any]]) {
        if let userDefaults = UserDefaults(suiteName: APP_GROUP) {
            userDefaults.set(array, forKey: DATA_KEY)
            userDefaults.synchronize()
        }
    }

    // MARK: - Call Screening
    public static func isCallScreeningRoleActive(completion: @escaping (Bool) -> Void) {
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: EXTENSION_ID) { status, error in
            if let error = error {
                print("[MassimaTranquillitaSDK] Errore getEnabledStatus: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(status == .enabled)
        }
    }

    public static func requestCallScreeningRole(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Attiva blocco chiamate",
            message: "Per abilitare il blocco chiamate, attiva l’estensione Massima Tranquillità nelle impostazioni di iOS.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel) { _ in completion(false) })
        alert.addAction(UIAlertAction(title: "Apri Impostazioni", style: .default) { _ in
            if #available(iOS 13.4, *) {
                CXCallDirectoryManager.sharedInstance.openSettings { error in
                    if let error = error {
                        print("[MassimaTranquillitaSDK] Errore aprendo impostazioni: \(error.localizedDescription)")
                    }
                }
            }
            completion(true)
        })
        viewController.present(alert, animated: true)
    }
}
