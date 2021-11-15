import Foundation

/// Utility class to handle value comparison and
/// matching for the campaign validation process.
internal struct MatchingUtility {

    static let timeToleranceMilliseconds = 1000

    static func compareValues(triggerAttributeValue: String,
                              eventAttributeValue: String,
                              operatorType: AttributeOperator) -> Bool {

        switch operatorType {
        case .equals:
            return eventAttributeValue == triggerAttributeValue
        case .isNotEqual:
            return eventAttributeValue != triggerAttributeValue
        case .isBlank:
            return eventAttributeValue.isEmpty
        case .isNotBlank:
            return !eventAttributeValue.isEmpty
        case .matchesRegex:
            return matches(regex: triggerAttributeValue, in: eventAttributeValue)
        case .doesNotMatchRegex:
            return !matches(regex: triggerAttributeValue, in: eventAttributeValue)
        case .invalid,
             .greaterThan,
             .lessThan:

            return false
        }
    }

    static func compareValues(triggerAttributeValue: Int,
                              eventAttributeValue: Int,
                              operatorType: AttributeOperator) -> Bool {

        switch operatorType {
        case .equals:
            return eventAttributeValue == triggerAttributeValue
        case .isNotEqual:
            return eventAttributeValue != triggerAttributeValue
        case .greaterThan:
            return eventAttributeValue > triggerAttributeValue
        case .lessThan:
            return eventAttributeValue < triggerAttributeValue
        case .invalid,
             .isBlank,
             .isNotBlank,
             .matchesRegex,
             .doesNotMatchRegex:

            return false
        }
    }

    static func compareValues(triggerAttributeValue: Double,
                              eventAttributeValue: Double,
                              operatorType: AttributeOperator) -> Bool {

        switch operatorType {
        case .equals:
            return eventAttributeValue.isEqual(to: triggerAttributeValue)
        case .isNotEqual:
            return !eventAttributeValue.isEqual(to: triggerAttributeValue)
        case .greaterThan:
            return triggerAttributeValue.isLess(than: eventAttributeValue)
        case .lessThan:
            return eventAttributeValue.isLess(than: triggerAttributeValue)
        case .invalid,
             .isBlank,
             .isNotBlank,
             .matchesRegex,
             .doesNotMatchRegex:

            return false
        }
    }

    static func compareValues(triggerAttributeValue: Bool,
                              eventAttributeValue: Bool,
                              operatorType: AttributeOperator) -> Bool {

        switch operatorType {
        case .equals:
            return eventAttributeValue == triggerAttributeValue
        case .isNotEqual:
            return eventAttributeValue != triggerAttributeValue
        case .invalid,
             .greaterThan,
             .lessThan,
             .isBlank,
             .isNotBlank,
             .matchesRegex,
             .doesNotMatchRegex:

            return false
        }
    }

    static func compareTimeValues(triggerAttributeValue: Int,
                                  eventAttributeValue: Int,
                                  operatorType: AttributeOperator) -> Bool {

        switch operatorType {

        case .equals:
            return (eventAttributeValue - triggerAttributeValue).magnitude <= timeToleranceMilliseconds
        case .isNotEqual:
            return (eventAttributeValue - triggerAttributeValue).magnitude > timeToleranceMilliseconds
        case .greaterThan:
            return (eventAttributeValue - triggerAttributeValue) > timeToleranceMilliseconds
        case .lessThan:
            return (eventAttributeValue - triggerAttributeValue) < -timeToleranceMilliseconds
        case .invalid,
             .isBlank,
             .isNotBlank,
             .matchesRegex,
             .doesNotMatchRegex:

            return false
        }
    }

    /// Searches a string to see if it matches a regular expression or not.
    /// - Parameter regex: The regular expression.
    /// - Parameter text: The text to apply the regex to.
    /// - Returns: `true` when the string matches the regex.
    fileprivate static func matches(regex: String, in text: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

            return !results.isEmpty
        } catch {
            return false
        }
    }
}
