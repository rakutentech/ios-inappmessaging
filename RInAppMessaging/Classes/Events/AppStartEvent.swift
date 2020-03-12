/// Pre-defined event that is used to signal the startup of the host application.
@objc public class AppStartEvent: Event {

    /// For broadcasting to RAT SDK. 'eventType' field will be removed.
    override var analyticsParameters: [String: Any] {
        return [
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

    required public init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}
