/// Extension to provide additional utilities to the String classes thats needed by IAM.
internal extension String {

    /// Returns the localized string provided by IAM's resource file.
    /// Provided value is used to match the keys in resource file.
    /// - Returns: The localized string.
    var localized: String {
        guard let bundle = Bundle.sdk else {
            return self
        }

        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
}
