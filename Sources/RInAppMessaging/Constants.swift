import typealias Foundation.TimeInterval

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
        static let viewAppeared = "view_appeared"
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
        static let retryCount = 3

        enum Default {
            static fileprivate(set) var initialRetryDelayMS = Int32(10000)
        }

        enum Randomized {
            static fileprivate(set) var initialRetryDelayMS = Int32(60000)
            static fileprivate(set) var backOffLowerBoundSeconds = Int32(1)
            static fileprivate(set) var backOffUpperBoundSeconds = Int32(60)
        }

        enum Tests {
            static func setInitialDelayMS(_ delay: Int32) {
                Default.initialRetryDelayMS = delay
                Randomized.initialRetryDelayMS = delay
            }

            static func setBackOffUpperBoundSeconds(_ bound: Int32) {
                Randomized.backOffUpperBoundSeconds = bound
            }
        }
    }
}
