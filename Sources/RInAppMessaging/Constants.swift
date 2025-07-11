import typealias Foundation.TimeInterval
import Foundation

internal enum Constants {

    enum CampaignMessage {
        static let imageRequestTimeoutSeconds: TimeInterval = 20
        static let imageResourceTimeoutSeconds: TimeInterval = 300
        static let carouselThreshold: Int = 5
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
        static let customFontNameTitleKey = "InAppMessagingCustomFontNameTitle"
        static let customFontNameTextKey = "InAppMessagingCustomFontNameText"
        static let customFontNameButtonKey = "InAppMessagingCustomFontNameButton"
        static let eventLoggerApiUrl = "InAppMessagingEventLoggerApiUrl"
        static let eventLoggerApiKey = "InAppMessagingEventLoggerApiKey"
        static let isEventLoggerEnabled = "InAppMessagingEventLoggerEnabled"
    }

    enum Versions {
        static let sdkVersion = "9.2.0-snapshot"
    }

    enum RAnalytics: String {
        case impressionsEventName = "_rem_iam_impressions"
        case pushPrimerEventName = "_rem_iam_pushprimer"
        case rmcImpressionsEventName = "_rem_rmc_iam_impressions"
        case rmcPushPrimerEventName = "_rem_rmc_iam_pushprimer"

        enum Keys {
            static let action = "action"
            static let timestamp = "timestamp"
            static let impressions = "impressions"
            static let campaignID = "campaign_id"
            static let subscriptionID = "subscription_id"
            static let pushPermission = "push_permission"
            static let deviceID = "device_id"
        }
    }

    enum RMC {
        static let subscriptionIDSuffix = "-rmc"
    }

    enum Retry {
        static let retryCount = 3

        enum Default {
            fileprivate static let defaultInitialRetryDelayMS = Int32(10000)
            fileprivate(set) static var initialRetryDelayMS = defaultInitialRetryDelayMS
        }

        enum Randomized {
            fileprivate static let defaultInitialRetryDelayMS = Int32(60000)
            fileprivate static let defaultBackOffLowerBoundSeconds = Int32(1)
            fileprivate static let defaultBackOffUpperBoundSeconds = Int32(60)
            fileprivate(set) static var initialRetryDelayMS = defaultInitialRetryDelayMS
            fileprivate(set) static var backOffLowerBoundSeconds = defaultBackOffLowerBoundSeconds
            fileprivate(set) static var backOffUpperBoundSeconds = defaultBackOffUpperBoundSeconds
        }

        enum Tests {
            static func setInitialDelayMS(_ delay: Int32) {
                Default.initialRetryDelayMS = delay
                Randomized.initialRetryDelayMS = delay
            }

            static func setBackOffUpperBoundSeconds(_ bound: Int32) {
                Randomized.backOffUpperBoundSeconds = bound
            }

            static func setDefaults() {
                Default.initialRetryDelayMS = Default.defaultInitialRetryDelayMS
                Randomized.initialRetryDelayMS = Randomized.defaultInitialRetryDelayMS
                Randomized.backOffUpperBoundSeconds = Randomized.defaultBackOffUpperBoundSeconds
            }
        }
    }

    enum Carousel {
        static let minHeight = 5.0
        static let defaultHeight = 250.0
    }
    
    enum Url {
        static let invalidURL = URL(string: "invalid")!
    }

    enum IAMErrorCode {
        case pingInvalidConfig
        case pingDecodingError
        case pingTooManyRequestsError
        case pingInvalidRequestError
        case pingInternalServerError
        case pingMissingMetadata
        case checkPermissionError
        case displayPerMissingEndpoint
        case displayPerMissingMetadata
        case displayPerUnexpectedParameters
        case displayPerFailedCreatingRequestBody
        case userDataCacheDecodingFailed
        case userDataCacheEncodingFailed
        case configTooManyRequestsError
        case configMissingOrInvalidSubscriptionId
        case configUnknownSubscriptionId
        case configInvalidRequestError
        case configInternalServerError
        case configInvalidConfigUrl
        case pushPrimerAuthorizationFailed
        case pushPrimerAuthorizationDenied
        case configJsonDecodingError
        case pingRequestError
        case impressionMissingEndpoint
        case impressionResponseError
        case impressionMissingMetadata
        case impressionMissingdParameters
        case impressionFailedCreatingRequestBody

        var errorCode: String {
            switch self {
            case .pingInvalidConfig:
                return "PING_INVALID_CONFIGURATION"
            case .pingDecodingError:
                return "PING_JSON_DECODING_ERROR"
            case .pingTooManyRequestsError:
                return "PING_TOO_MANY_REQUESTS_ERROR:"
            case .pingInvalidRequestError:
                return "PING_INVALID_REQUEST_ERROR:"
            case .pingInternalServerError:
                return "PING_INTERNAL_SERVER_ERROR:"
            case .pingMissingMetadata:
                return "PING_MISSING_METADATA"
            case .checkPermissionError:
                return "CHECK_PERMISSION_RESPONSE_ERROR"
            case .displayPerMissingEndpoint:
                return "DISPLAY_PERMISSION_MISSING_ENDPOINT"
            case .displayPerMissingMetadata:
                return "DISPLAY_PERMISSION_MISSING_METADATA"
            case .displayPerUnexpectedParameters:
                return "DISPLAY_PERMISSION_UNEXPECTED_PARAMETERS"
            case .userDataCacheDecodingFailed:
                return "USER_CACHE_DECODING_FAILED"
            case .userDataCacheEncodingFailed:
                return "USERDATA_CACHE_ENCODING_FAILED"
            case .configTooManyRequestsError:
                return "CONFIG_TOO_MANY_REQUESTS_ERROR:"
            case .configMissingOrInvalidSubscriptionId:
                return "CONFIG_MISSING_OR_INVALID_SUBSCRIPTION_ID:"
            case .configUnknownSubscriptionId:
                return "CONFIG_UNKNOWN_SUBSCRIPTION_ID:"
            case .configInvalidRequestError:
                return "CONFIG_INVALID_REQUEST_ERROR:"
            case .configInternalServerError:
                return "CONFIG_INTERNAL_SERVER_ERROR:"
            case .configJsonDecodingError:
                return "CONFIGURE_JSON_DECODING_ERROR"
            case .displayPerFailedCreatingRequestBody:
                return "DISPLAY_PERMISSION_FAILED_CREATING_REQUEST_BODY"
            case .configInvalidConfigUrl:
                return "CONFIGURE_INVALID_CONFIGURATION_URL"
            case .pushPrimerAuthorizationFailed:
                return "PUSH_AUTHORIZATION_FAILED"
            case .pushPrimerAuthorizationDenied:
                return "PUSH_AUTHORIZATION_DENIED"
            case .pingRequestError:
                return "PING_REQUEST_ERROR"
            case .impressionMissingEndpoint:
                return "IMPRESSION_MISSING_ENDPOINT"
            case .impressionResponseError:
                return "IMPRESSION_RESPONSE_ERROR:"
            case .impressionMissingMetadata:
                return "IMPRESSION_MISSING_METADATA"
            case .impressionMissingdParameters:
                return "IMPRESSION_MISSING_PARAMETERS"
            case .impressionFailedCreatingRequestBody:
                return "IMPRESSION_ERROR_ENCODING_IMPRESSION_REQUEST"
            }
        }

        var errorMessage: String {
            switch self {
            case .pingInvalidConfig:
                return "Ping configuration is invalid."
            case .pingDecodingError:
                return "Failed to decode ping response."
            case .pingTooManyRequestsError:
                return "Too many ping requests."
            case .pingInvalidRequestError:
                return "Ping request was invalid."
            case .pingInternalServerError:
                return "Internal server error during ping."
            case .pingMissingMetadata:
                return "Failed creating a request body"
            case .checkPermissionError:
                return "Couldn't get a valid response from display permission endpoint."
            case .displayPerMissingEndpoint:
                return "Missing endpoint in display permission request."
            case .displayPerMissingMetadata:
                return "Missing metadata in display permission request."
            case .displayPerUnexpectedParameters:
                return "Unexpected parameters in display permission request."
            case .userDataCacheDecodingFailed:
                return "Failed to decode cached user data."
            case .userDataCacheEncodingFailed:
                return "Failed to encode user data for caching."
            case .configTooManyRequestsError:
                return "Too many configuration requests sent in a short period."
            case .configMissingOrInvalidSubscriptionId:
                return "Missing or invalid subscription ID in the configuration request."
            case .configUnknownSubscriptionId:
                return "The provided subscription ID is unknown."
            case .configInvalidRequestError:
                return "The configuration request was invalid or malformed."
            case .configInternalServerError:
                return "An internal server error occurred while fetching the configuration."
            case .displayPerFailedCreatingRequestBody:
                return "Failed creating display permission request body"
            case .configInvalidConfigUrl:
                return "Configuration Url is Invalid"
            case .pushPrimerAuthorizationFailed:
                return "PushPrimer: UNUserNotificationCenter requestAuthorization failed."
            case .pushPrimerAuthorizationDenied:
                return "PushPrimer: User has not granted authorization."
            case .configJsonDecodingError:
                return "JSON Decoding Error for Config API"
            case .pingRequestError:
                return "Ping Request Error"
            case .impressionMissingEndpoint:
                return "Error retrieving InAppMessaging Impression URL"
            case .impressionResponseError:
                return "Couldn't get a valid response from impression endpoint."
            case .impressionMissingMetadata:
                return "Missing metadata in impression request."
            case .impressionMissingdParameters:
                return "Unexpected parameters in impression request."
            case .impressionFailedCreatingRequestBody:
                return "Error encoding impression request"
            }
        }
    }
}
