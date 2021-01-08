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
        let defaultBundle = self.init(identifier: "org.cocoapods.RInAppMessaging") ?? .bundle(bundleIdSubstring: "RInAppMessaging")
        assert(defaultBundle != nil, "In-App Messaging SDK is not integrated properly - framework bundle not found")
        return defaultBundle
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

    static func bundle(bundleIdSubstring: String) -> Bundle? {
        return (allBundles + allFrameworks).first(where: { $0.bundleIdentifier?.contains(bundleIdSubstring) == true })
    }
}
