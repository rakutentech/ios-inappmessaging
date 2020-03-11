/// Enum of trigger's attribute operators for matching.
internal enum AttributeOperator: Int, Codable {
    case invalid = 0
    case equals
    case isNotEqual
    case greaterThan
    case lessThan
    case isBlank
    case isNotBlank
    case matchesRegex
    case doesNotMatchRegex
}
