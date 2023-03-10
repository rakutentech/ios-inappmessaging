import Foundation

/// Pre-defined event that is used to signal the success of a login action.
@objc public class LoginSuccessfulEvent: Event {

    /// For broadcasting to RAT SDK. 'eventType' field will be removed.
    override var analyticsParameters: [String: Any] {
        [
            "eventName": super.name,
            "timestamp": super.timestamp
        ]
    }

    @objc
    public init() {
        super.init(type: EventType.loginSuccessful,
                   name: Constants.Event.loginSuccessful)
    }

    init(timestamp: Int64) {
        super.init(type: EventType.loginSuccessful,
                   name: Constants.Event.loginSuccessful,
                   timestamp: timestamp)
    }

    required public init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}
