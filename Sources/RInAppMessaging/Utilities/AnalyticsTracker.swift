import class UIKit.UIDevice

#if SWIFT_PACKAGE
import class RSDKUtilsMain.AnalyticsBroadcaster
#else
import class RSDKUtils.AnalyticsBroadcaster
#endif

internal struct AnalyticsTracker {
    static func sendEventName(_ name: Constants.RAnalytics, dataObject: [String: Any] = [:]) {
        var eventData = dataObject
        eventData[Constants.RAnalytics.Keys.deviceID] = UIDevice.deviceID
        
        if let customAccNumber = BundleInfo.rmcRATAccountId, RInAppMessaging.isRMCEnvironment {
            let rmcEventName = name.rawValue == Constants.RAnalytics.impressionsEventName.rawValue ? Constants.RAnalytics.rmcImpressionsEventName : Constants.RAnalytics.rmcPushPrimerEventName
            AnalyticsBroadcaster.sendEventName(rmcEventName.rawValue, dataObject: eventData, customAccountNumber: customAccNumber)
        }
        AnalyticsBroadcaster.sendEventName(name.rawValue, dataObject: eventData)
    }
}
