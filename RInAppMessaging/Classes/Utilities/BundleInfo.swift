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
        if let defaultBundle = self.init(identifier: "org.cocoapods.RInAppMessaging") {
            return defaultBundle
        } else {
            return (allBundles + allFrameworks).first(where: { $0.bundleIdentifier?.contains("RInAppMessaging") == true })
        }
    }
    static var sdkAssets: Bundle? {
        guard let sdkBundlePath = sdk?.resourcePath else {
            return nil
        }
        return self.init(path: sdkBundlePath.appending("/RInAppMessagingAssets.bundle"))
    }
    static var tests: Bundle? {
        return self.init(identifier: "org.cocoapods.Tests")
    }
}
