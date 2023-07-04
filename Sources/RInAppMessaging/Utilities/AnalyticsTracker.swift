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
        AnalyticsBroadcaster.sendEventName(name.rawValue,
                                           dataObject: eventData)
    }
}
