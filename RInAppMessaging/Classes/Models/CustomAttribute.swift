/// Model to represent a custom attribute that is returned by the ping request in triggers.
@objc
public class CustomAttribute: NSObject {
    let name: String
    let value: Any
    let type: AttributeType

    /// For broadcasting to RAT SDK. 'type' field will be removed.
    var dictionaryRepresentation: [String: Any] {
        return [
            "name": name,
            "value": value
        ]
    }

    @objc
    public init(withKeyName name: String, withStringValue value: String) {
        self.name = name.lowercased()
        self.value = value
        self.type = .string
    }

    @objc
    public init(withKeyName name: String, withIntValue value: Int) {
        self.name = name.lowercased()
        self.value = value
        self.type = .integer
    }

    @objc
    public init(withKeyName name: String, withDoubleValue value: Double) {
        self.name = name.lowercased()
        self.value = value
        self.type = .double
    }

    @objc
    public init(withKeyName name: String, withBoolValue value: Bool) {
        self.name = name.lowercased()
        self.value = value
        self.type = .boolean
    }

    @objc
    public init(withKeyName name: String, withTimeInMilliValue value: Int) {
        self.name = name.lowercased()
        self.value = value
        self.type = .timeInMilliseconds
    }
}
