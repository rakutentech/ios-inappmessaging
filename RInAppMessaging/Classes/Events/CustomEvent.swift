/// Custom event that the host app can call with a custom event name.
@objc public class CustomEvent: Event {

    var customAttributes: [CustomAttribute]?

    /// For broadcasting to RAT SDK. 'eventType' field will be removed.
    override var analyticsParameters: [String: Any] {

        let attributesList = (customAttributes ?? []).map {
            $0.dictionaryRepresentation
        }

        return [
            "eventName": super.name,
            "timestamp": super.timestamp,
            "customAttributes": attributesList
        ]
    }

    @objc
    public init(withName name: String, withCustomAttributes customAttributes: [CustomAttribute]?) {

        self.customAttributes = customAttributes

        super.init(type: EventType.custom,
                   name: name)
    }

    init(withName name: String, withCustomAttributes customAttributes: [CustomAttribute]?, timestamp: Int) {

        self.customAttributes = customAttributes

        super.init(type: EventType.custom,
                   name: name,
                   timestamp: timestamp)
    }

    required public init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }

    /// Create a mapping used to return a dictionary of the customAttributes list.
    /// - Returns: A dictionary of the customAttributes list with attribute name as a key
    override func getAttributeMap() -> [String: CustomAttribute]? {
        guard let customAttributes = self.customAttributes else {
            return nil
        }

        var attributeMap: [String: CustomAttribute] = [:]

        for attribute in customAttributes {
            attributeMap[attribute.name] = attribute
        }

        return attributeMap
    }
}
