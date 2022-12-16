import Foundation

/// Bridges NSString functions to help with conversion to Foundation primitive types
extension String {

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
