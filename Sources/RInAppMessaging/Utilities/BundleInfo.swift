import Foundation
#if canImport(RSDKUtilsMain)
import RSDKUtilsMain // SPM version
#else
import RSDKUtils
#endif

internal class BundleInfo {

    class var applicationId: String? {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String
    }

    class var appVersion: String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    class var inAppSdkVersion: String? {
        guard let versionsPlistURL = Bundle.sdkAssets?.url(forResource: "Versions", withExtension: "plist"),
              let plistData = try? Data(contentsOf: versionsPlistURL),
              let versions = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
                  assertionFailure("Can't read Versions.plist in Resources folder")
                  return nil
              }
        return versions[Constants.Versions.sdkVersionKey] as? String
    }

    class var inAppSubscriptionId: String? {
        return Bundle.main.infoDictionary?[Constants.Info.subscriptionIDKey] as? String
    }

    class var inAppConfigurationURL: String? {
        return Bundle.main.infoDictionary?[Constants.Info.configurationURLKey] as? String
    }

    class var customFontNameTitle: String? {
        Bundle.main.infoDictionary?[Constants.Info.customFontNameTitleKey] as? String
    }

    class var customFontNameText: String? {
        Bundle.main.infoDictionary?[Constants.Info.customFontNameTextKey] as? String
    }

    class var customFontNameButton: String? {
        Bundle.main.infoDictionary?[Constants.Info.customFontNameButtonKey] as? String
    }
}

internal extension Bundle {

    static var sdkAssets: Bundle? {
        #if SWIFT_PACKAGE
        module
        #else

        guard let sdkBundleURL = sdk?.resourceURL else {
            return nil
        }
        return .init(url: sdkBundleURL.appendingPathComponent("RInAppMessagingResources.bundle"))
        #endif
    }

    static var unitTests: Bundle? {
        .init(identifier: "jp.co.rakuten.inappmessaging.Tests") ?? .init(identifier: "Tests")
    }

    private static var sdk: Bundle? {
        sdkBundle(name: "RInAppMessaging")
    }
}
