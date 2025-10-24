import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        // Legge direttamente i numeri dall’App Group senza importare il framework
        let userDefaults = UserDefaults(suiteName: "group.com.massimatranquillita")
        let saved = userDefaults?.array(forKey: "CALLER_LIST") as? [[String: Any]] ?? []

        var numbers = [UInt64]()
        for dict in saved {
            if let nums = dict["numbersToAdd"] as? [NSNumber] {
                numbers.append(contentsOf: nums.map { $0.uint64Value })
            }
        }

        for number in numbers.sorted() {
            context.addBlockingEntry(withNextSequentialPhoneNumber: CXCallDirectoryPhoneNumber(number))
        }

        context.completeRequest()
        print("[CallDirectoryExtension] Request completed ✅")
    }
}
