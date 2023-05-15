import RInAppMessaging

enum EventHelper {
    static func customAttributeFromData(name: String, value: String, type: String) -> CustomAttribute? {
        guard !name.isEmpty && !value.isEmpty && !type.isEmpty else {
            return nil
        }

        switch type {
        case AttributeTypeKeys.string.rawValue:
            return CustomAttribute(withKeyName: name,
                                   withStringValue: value as String)

        case AttributeTypeKeys.boolean.rawValue where value.hasBoolValue:
            return CustomAttribute(withKeyName: name,
                                   withBoolValue: value.boolValue)

        case AttributeTypeKeys.integer.rawValue where value.hasIntegerValue:
            return CustomAttribute(withKeyName: name,
                                   withIntValue: value.integerValue)

        case AttributeTypeKeys.double.rawValue where value.hasDoubleValue:
            return CustomAttribute(withKeyName: name,
                                   withDoubleValue: value.doubleValue)

        case AttributeTypeKeys.date.rawValue where value.hasIntegerValue:
            return CustomAttribute(withKeyName: name,
                                   withTimeInMilliValue: value.integerValue)

        default:
            return nil
        }
    }
}
