// This file should be removed after RSDKUtils 3.1.0 release
import Foundation

extension NSNotification.Name {
    static let rAnalyticsCustomEvent = Notification.Name(rawValue: "com.rakuten.esd.sdk.events.custom")
}

/// Functionality temporarily copied from RSDKUtils 3.1.0-snapshot
internal enum IAMAnalyticsBroadcaster {
    static func sendEventName(_ name: String, dataObject: [String: Any]? = nil, customAccountNumber: NSNumber? = nil) {
        var parameters: [String: Any] = ["eventName": name]
        if let dataObject = dataObject {
            parameters["eventData"] = dataObject
        }
        if let customAccountNumber = customAccountNumber, customAccountNumber.intValue > 0 {
            parameters["customAccNumber"] = customAccountNumber
        }

        NotificationCenter.default.post(name: .rAnalyticsCustomEvent, object: parameters)
    }
}
