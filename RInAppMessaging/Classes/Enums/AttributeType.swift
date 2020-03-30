internal enum AttributeType: Int, Codable {
    private enum CodingKeys: String, CodingKey {
        case invalid
        case string
        case integer
        case double
        case boolean
        case timeInMilliseconds = "timeInMilli"
    }

    case invalid = 0
    case string
    case integer
    case double
    case boolean
    case timeInMilliseconds
}
