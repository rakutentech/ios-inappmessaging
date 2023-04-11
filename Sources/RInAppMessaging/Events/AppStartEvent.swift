import Foundation

/// Pre-defined event that is used to signal the startup of the host application.
@objc public class AppStartEvent: Event {

    /// For broadcasting to RAT SDK. 'eventType' field will be removed.
    override var analyticsParameters: [String: Any] {
        [
            "eventName": super.name,
            "timestamp": super.timestamp
        ]
    }

    @objc
    public init() {
        super.init(type: EventType.appStart,
                   name: Constants.Event.appStart)
    }

    init(timestamp: Int64) {
        super.init(type: EventType.appStart,
                   name: Constants.Event.appStart,
                   timestamp: timestamp)
    }
}
