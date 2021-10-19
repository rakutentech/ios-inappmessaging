import RSDKUtils

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
        sdkBundle(name: "RInAppMessaging")
    }
    static var sdkAssets: Bundle? {
        guard let sdkBundlePath = sdk?.resourcePath else {
            return nil
        }
        return self.init(path: sdkBundlePath.appending("/RInAppMessagingAssets.bundle"))
    }
    static var tests: Bundle? {
        return self.init(identifier: "jp.co.rakuten.inappmessaging.Tests")
    }
}
