/// Extension to Bundle class to provide computed properties required by InAppMessaging.
internal extension Bundle {

    static var sdk: Bundle? {
        return Bundle(identifier: "org.cocoapods.RInAppMessaging")
    }

    static var applicationId: String? {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String
    }

    static var appVersion: String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    static var inAppSdkVersion: String? {
        return sdk?.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    static var inAppSubscriptionId: String? {
        return Bundle.main.infoDictionary?[Constants.Info.subscriptionIDKey] as? String
    }

    static var inAppConfigurationURL: String? {
        return Bundle.main.infoDictionary?[Constants.Info.configurationURLKey] as? String
    }
}
