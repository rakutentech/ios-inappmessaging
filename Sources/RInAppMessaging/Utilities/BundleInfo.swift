import Foundation

#if SWIFT_PACKAGE
import RSDKUtilsMain
#else
import RSDKUtils
#endif

internal class BundleInfo {

    class var bundle: Bundle {
        .main
    }

    class var rmcBundle: Bundle? {
        .rmcResources
    }
        
    class var applicationId: String? {
        bundle.infoDictionary?["CFBundleIdentifier"] as? String
    }

    class var appVersion: String? {
        bundle.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    class var inAppSubscriptionId: String? {
        bundle.infoDictionary?[Constants.Info.subscriptionIDKey] as? String
    }

    class var inAppConfigurationURL: String? {
        bundle.infoDictionary?[Constants.Info.configurationURLKey] as? String
    }

    class var customFontNameTitle: String? {
        bundle.infoDictionary?[Constants.Info.customFontNameTitleKey] as? String
    }

    class var customFontNameText: String? {
        bundle.infoDictionary?[Constants.Info.customFontNameTextKey] as? String
    }

    class var customFontNameButton: String? {
        bundle.infoDictionary?[Constants.Info.customFontNameButtonKey] as? String
    }
    
    class var rmcSdkVersion: String? {
        rmcBundle?.infoPlistValues()?["rmcSdkVersion"] as? String
    }
    
    class var rmcRATAccountId: NSNumber? {
        guard let accountId = rmcBundle?.infoPlistValues()?["rmcRATAccountId"] as? Int else {
                    return nil
        }
        return NSNumber(value: accountId)
    }

    class var eventLoggerApiUrl: String? {
        bundle.infoDictionary?[Constants.Info.eventLoggerApiUrl] as? String
    }

    class var eventLoggerApiKey: String? {
        bundle.infoDictionary?[Constants.Info.eventLoggerApiKey] as? String
    }

    class var isEventLoggerEnabled: Bool? {
        bundle.infoDictionary?[Constants.Info.isEventLoggerEnabled] as? Bool
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

    static var rmcResources: Bundle? {
        guard let rmcBundleUrl = main.resourceURL?.appendingPathComponent("RMC_RMC.bundle"),
              let bundle = Bundle(url: rmcBundleUrl) else {
            return nil
        }
        return bundle
    }

    private static var sdk: Bundle? {
        sdkBundle(name: "RInAppMessaging")
    }
    
    fileprivate func infoPlistValues() -> [String: Any]?  {
        guard let path = path(forResource: "RmcInfo", ofType: "plist"),
              let infoDict = NSDictionary(contentsOfFile: path) as? [String: Any]
        else { return nil }
        return infoDict
    }
}
