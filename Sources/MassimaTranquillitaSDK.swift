//
//  MassimaTranquillitaSDK.swift
//  MassimaTranquillitaSDK
//
//  Created by Davide Dinoi on 17/10/25.
//
import UIKit
import CallKit

class Caller: Codable {
    let name: String
    let numbersToAdd: [UInt64]
    let numbersToRemove: [UInt64]
    
    init(dictionary: [String: Any]) {
        self.name = dictionary["name"] as? String ?? ""
        self.numbersToAdd = (dictionary["numbersToAdd"] as? [NSNumber])?.map { $0.uint64Value } ?? []
        self.numbersToRemove = (dictionary["numbersToRemove"] as? [NSNumber])?.map { $0.uint64Value } ?? []
    }
}

public class MassimaTranquillitaSDK {
    
    public struct Constants {
        public static let DATA_KEY = "CALLER_LIST"
        public static let APP_GROUP = "group.com.massimatranquillita"
    }
    
    public static let EXTENSION_ID = "com.massimatranquillita.CallDirectoryExtension"
    
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
    
    // MARK: - Core Logic (Spostata qui)
    public static func handleCallDirectoryRequest(context: CXCallDirectoryExtensionContext) {
            var callerList = getCallerList() // Chiama il metodo statico helper
            
            if callerList.isEmpty {
                callerList.append(Caller(dictionary: ["name":"Test","numbersToAdd":[391234567890],"numbersToRemove":[]]))
                print("[MassimaTranquillitaSDK] Added dummy caller for testing")
            }
            
            addBlockingNumbers(callerList: callerList, context: context) // Chiama il metodo statico helper
        }
        
        private static func addBlockingNumbers(callerList: [Caller], context: CXCallDirectoryExtensionContext) {
            var allNumbers = Set<UInt64>()
            
            for caller in callerList {
                allNumbers.formUnion(caller.numbersToAdd)
            }
            
            let sortedNumbers = allNumbers.sorted()
            for number in sortedNumbers {
                context.addBlockingEntry(withNextSequentialPhoneNumber: CXCallDirectoryPhoneNumber(number))
            }
        }
        
        private static func getCallerList() -> [Caller] {
            // Usa le costanti incapsulate
            guard let userDefaults = UserDefaults(suiteName: MassimaTranquillitaSDK.Constants.APP_GROUP),
                  let savedArray = userDefaults.array(forKey: MassimaTranquillitaSDK.Constants.DATA_KEY) as? [[String: Any]] else {
                print("[MassimaTranquillitaSDK] No callers found")
                return []
            }
            
            print("[MassimaTranquillitaSDK] Loaded \(savedArray.count) callers")
            return savedArray.map { Caller(dictionary: $0) }
        }
}
