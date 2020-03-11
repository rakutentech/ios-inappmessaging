/// Extension to Locale class to provide computed properties required by InAppMessaging.
internal extension Locale {
    static var formattedCode: String? {
        return "\(Locale.current)".components(separatedBy: " ").first
    }
}
