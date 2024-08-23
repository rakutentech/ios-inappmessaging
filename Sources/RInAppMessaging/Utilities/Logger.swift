import os
import Foundation

extension OSLog {
    static let sdk = OSLog(category: "RInAppMessaging SDK")

    private convenience init(category: String, bundle: Bundle = Bundle(for: Logger.self)) {
        let identifier = bundle.infoDictionary?["CFBundleIdentifier"] as? String
        self.init(subsystem: (identifier ?? "").appending(".logs"), category: category)
    }
}

 class Logger {
     // Debug Logging
     class func debug(_ message: String) {
        #if DEBUG
         print("InAppMessaging: " + message)
        #else
         os_log("%s", log: OSLog.sdk, type: .error, message)
        #endif
     }

     class func debugLog(_ message: String) {
        #if DEBUG
         // do nothing
        #else
         os_log("%s", log: OSLog.sdk, type: .error, message)
        #endif
     }
 }
