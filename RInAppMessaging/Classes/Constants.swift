/// Struct to organize all constants used by InAppMessaing SDK.
internal enum Constants {

    /// Configuration.
    enum Configuration {
        static let milliBetweenDisplays = 3000 // Default value.
    }

    /// Constants used to build request body.
    enum Request {
        static let appID = "appId"
        static let platform = "platform"
        static let appVersion = "appVersion"
        static let sdkVersion = "sdkVersion"
        static let locale = "locale"
        static let subscriptionID = "subscriptionId"
        static let userIdentifiers = "userIdentifiers"
        static let campaignID = "campaignId"
        static let deviceID = "device_id" // Snake_case rather than camelCase to unify with backend.
        static let authorization = "Authorization" // HTTP header for access token.
        static let subscriptionHeader = "Subscription-Id"// HTTP header for sub id.
    }

    /// Constants for Event object.
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

    /// Directories used for SDK.
    enum File {
        static let eventLogs = "InAppMessagingEventLogs.plist"
        static let testFileForEventLogs = "InAppTests.plist"
    }

    /// Key names for Info.plist.
    enum Info {
        static let subscriptionIDKey = "InAppMessagingAppSubscriptionID"
        static let configurationURLKey = "InAppMessagingConfigurationURL"
    }

    /// Key names for key value pairs.
    enum KVObject {
        static let campaign = "campaign"
    }

    /// Constants for RAT SDK event names.
    enum RAnalytics {
        static let impressions = "InAppMessaging_impressions"
        static let events = "InAppMessaging_events"
    }
}
