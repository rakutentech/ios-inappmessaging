/// Enum of value type for custom event attributes.
internal enum AttributeType: Int, Codable {
    case invalid = 0
    case string
    case integer
    case double
    case boolean
    case timeInMilli
}
