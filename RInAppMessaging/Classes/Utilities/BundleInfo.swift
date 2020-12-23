internal class BundleInfo {

    class var applicationId: String? {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String
    }

    class var appVersion: String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    class var inAppSdkVersion: String? {
        return Bundle.sdk?.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    class var inAppSubscriptionId: String? {
        return Bundle.main.infoDictionary?[Constants.Info.subscriptionIDKey] as? String
    }

    class var inAppConfigurationURL: String? {
        return Bundle.main.infoDictionary?[Constants.Info.configurationURLKey] as? String
    }
}

internal extension Bundle {

    static var sdk: Bundle? {
        return Bundle(identifier: "org.cocoapods.RInAppMessaging")
    }
    static var sdkAssets: Bundle? {
        guard let sdkBundlePath = sdk?.resourcePath else {
            return nil
        }
        return Bundle(path: sdkBundlePath.appending("/RInAppMessagingAssets.bundle"))
    }
    static var tests: Bundle? {
        return Bundle(identifier: "org.cocoapods.Tests")
    }
}
