//import typealias Foundation.TimeInterval
import UIKit

public class Tama2 {
    public enum Tama {
        public static var v = {
//            #if SWIFT_PACKAGE
//            Bundle(for: Self.self).shortVersion
//            #else
//            Bundle(for: Self.self).value(for: <#T##String#>)
            Bundle(for: Self.self).object(forInfoDictionaryKey: "CFBundleVersion")
//            #endif
        }()
        
    }
//    public let b = Bundle(for: Self.self).shortVersion
}


internal enum Constants {

    enum CampaignMessage {
        static let defaultIntervalBetweenDisplaysInMS = 3000
        static let imageRequestTimeoutSeconds: TimeInterval = 20
        static let imageResourceTimeoutSeconds: TimeInterval = 300
    }

    enum Request {
        static let campaignID = "campaignId"

        enum Header {
            static let subscriptionID = "Subscription-Id"
            static let deviceID = "device_id"
            static let authorization = "Authorization"
        }
    }

    enum Event {
        static let eventType = "eventType"
        static let timestamp = "timestamp"
        static let eventName = "eventName"
        static let customAttributes = "customAttributes"
        static let appStart = "app_start"
        static let loginSuccessful = "login_successful"
        static let purchaseSuccessful = "purchase_successful"
        static let invalid = "invalid"
        static let custom = "custom"
    }

    enum File {
        static let eventLogs = "InAppMessagingEventLogs.plist"
        static let testFileForEventLogs = "InAppTests.plist"
    }

    enum Info {
        static let subscriptionIDKey = "InAppMessagingAppSubscriptionID"
        static let configurationURLKey = "InAppMessagingConfigurationURL"
    }

    enum Versions {
        static let sdkVersionKey = "IAMCurrentModuleVersion"
    }

    enum RAnalytics {
        static let impressions = "InAppMessaging_impressions"
        static let loggedEvent = "InAppMessaging_triggeredEvent"
    }

    enum Retry {
        enum Default {
            static let initialRetryDelayMS = Int32(10000)
        }

        enum TooManyRequestsError {
            static let initialRetryDelayMS = Int32(60000)
            static let backOffLowerBoundInSecond = Int32(1) // second
            static let backOffUpperBoundInSecond = Int32(60) // second
        }
    }
}
