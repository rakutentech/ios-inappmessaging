import Foundation

/// Bridges NSString functions to help with conversion to Foundation primitive types
extension String {

    /// Returns the localized string provided by IAM's resource file.
    /// Provided value is used to match the keys in resource file.
    /// - Returns: The localized string.
    var localized: String {
        return NSLocalizedString(self, bundle: Bundle.main, comment: "")
    }

    /// broadly matches NSString.boolValue behaviour
    var hasBoolValue: Bool {
        Set<Character?>([
            "t", "T", // true
            "f", "F", // false
            "y", "Y", // yes
            "n", "N", // no
            "0", "1"]).contains(first)
    }

    var boolValue: Bool {
        (self as NSString).boolValue
    }

    var hasIntegerValue: Bool {
        Int(self) != nil
    }

    var integerValue: Int {
        (self as NSString).integerValue
    }

    var hasDoubleValue: Bool {
        Double(self) != nil
    }

    var doubleValue: Double {
        (self as NSString).doubleValue
    }
}
