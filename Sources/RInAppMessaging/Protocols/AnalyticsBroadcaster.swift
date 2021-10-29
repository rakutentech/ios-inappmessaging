import Foundation

/// Protocol implemented by any class that wants to broadcast events to Analytics SDK.
internal protocol AnalyticsBroadcaster {
    /// This method will broadcast an event to the Analytics SDK for them to send to RAT.
    /// - Parameter name: Name of the event to be sent to Analytics SDK.
    /// - Parameter dataObject: Optional dictionary to pass in any other data to RAT.
    func sendEventName(_ name: String, _ dataObject: [String: Any]?)
}

extension AnalyticsBroadcaster {

    func sendEventName(_ name: String, _ dataObject: [String: Any]?) {
        var parameters = [String: Any]()
        parameters["eventName"] = name
        if let data = dataObject {
            parameters["eventData"] = data
        }

        let notificationName = Notification.Name("com.rakuten.esd.sdk.events.custom")
        NotificationCenter.default.post(name: notificationName, object: parameters)
    }
}
