import Foundation
/// Model to represent a custom attribute that is returned by the ping request in triggers.
@objc
public class CustomAttribute: NSObject {
    let name: String
    let value: Any
    let type: AttributeType

    /// For broadcasting to RAT SDK. 'type' field will be removed.
    var dictionaryRepresentation: [String: Any] {
        [
            "name": name,
            "value": value
        ]
    }

    @objc
    public init(withKeyName name: String, withStringValue value: String) {
        self.name = name.lowercased()
        self.value = value.lowercased()
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

    @objc
    public init(withKeyName name: String, withInvalid value: Any) {
        self.name = name.lowercased()
        self.value = value
        self.type = .invalid
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? CustomAttribute else {
            return false
        }

        // casting to NSObject to make comparison possible (workaround)
        guard let selfValue = value as? NSObject,
            let objectValue = object.value as? NSObject else {
                return false
        }

        return selfValue == objectValue && object.type == type && object.name == name
    }
}
