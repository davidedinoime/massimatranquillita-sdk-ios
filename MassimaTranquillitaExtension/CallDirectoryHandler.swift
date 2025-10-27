import Foundation
import CallKit

let DATA_KEY = "CALLER_LIST"
let APP_GROUP = "group.io.massimatranquillitatest"

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

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        let callerList = getCallerList()

        if context.isIncremental {
            updateBlockingNumbers(callerList: callerList, context: context)
        } else {
            addBlockingNumbers(callerList: callerList, context: context)
        }

        context.completeRequest()
        print("[CallDirectoryExtension] Request completed ✅")
    }

    // MARK: - Add Numbers
    private func addBlockingNumbers(callerList: [Caller], context: CXCallDirectoryExtensionContext) {
        var allNumbers = Set<UInt64>()

        for caller in callerList {
            allNumbers.formUnion(caller.numbersToAdd)
        }

        let sortedNumbers = allNumbers.sorted()
        for number in sortedNumbers {
            context.addBlockingEntry(withNextSequentialPhoneNumber: CXCallDirectoryPhoneNumber(number))
        }
    }

    // MARK: - Update Numbers Incrementally
    private func updateBlockingNumbers(callerList: [Caller], context: CXCallDirectoryExtensionContext) {
        var numbersToAdd = Set<UInt64>()
        var numbersToRemove = Set<UInt64>()

        for caller in callerList {
            numbersToAdd.formUnion(caller.numbersToAdd)
            numbersToRemove.formUnion(caller.numbersToRemove)
        }

        let sortedAdd = numbersToAdd.sorted()
        let sortedRemove = numbersToRemove.sorted()

        for number in sortedAdd {
            context.addBlockingEntry(withNextSequentialPhoneNumber: CXCallDirectoryPhoneNumber(number))
        }

        for number in sortedRemove {
            context.removeBlockingEntry(withPhoneNumber: CXCallDirectoryPhoneNumber(number))
        }
    }

    // MARK: - Load Data from App Group
    private func getCallerList() -> [Caller] {
        guard let userDefaults = UserDefaults(suiteName: APP_GROUP),
              let savedArray = userDefaults.array(forKey: DATA_KEY) as? [[String: Any]] else {
            print("[CallDirectoryExtension] No callers found")
            return []
        }

        print("[CallDirectoryExtension] Loaded \(savedArray.count) callers")
        return savedArray.map { Caller(dictionary: $0) }
    }
}
