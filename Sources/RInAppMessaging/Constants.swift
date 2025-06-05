import typealias Foundation.TimeInterval

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
    
    enum RMCErrorCode {
        static let pingInvalidConfig = "PING_INVALID_CONFIGURATION"
        static let pingDecodingError = "PING_JSON_DECODING_ERROR"
        static let pingTooManyRequestsError = "PING_TOO_MANY_REQUESTS_ERROR"
        static let invalidRequestError = "PING_INVALID_REQUEST_ERROR"
        static let internalServerError = "PING_INTERNAL_SERVER_ERROR"
        static let pingMissingMetadata = "PING_MISSING_METADATA"
        static let checkPermissionError = "CHECK_PERMISSION_RESPONSE_ERROR"
        static let displayPerMissingEndpoint = "DISPLAY_PERMISSION_MISSING_ENDPOINT"
        static let displayPerMissingMetadata = "DISPLAY_PERMISSION_MISSING_METADATA"
        static let displayPerUnexpectedParameters = "DISPLAY_PERMISSION_UNEXPECTED_PARAMETERS"
        static let userDataCacheDecodingFailed = "USER_CACHE_DECODING_FAILED"
        static let userDataCacheEncodingFailed = "USERDATA_CACHE_ENCODING_FAILED"
    }
    enum IAMErrorCode {
        case pingInvalidConfig
        case pingDecodingError
        case pingTooManyRequestsError
        case invalidRequestError
        case internalServerError
        case pingMissingMetadata
        case checkPermissionError
        case displayPerMissingEndpoint
        case displayPerMissingMetadata
        case displayPerUnexpectedParameters
        case userDataCacheDecodingFailed
        case userDataCacheEncodingFailed

        var errorCode: String {
            switch self {
            case .pingInvalidConfig:
                return "PING_INVALID_CONFIGURATION"
            case .pingDecodingError:
                return "PING_JSON_DECODING_ERROR"
            case .pingTooManyRequestsError:
                return "PING_TOO_MANY_REQUESTS_ERROR"
            case .invalidRequestError:
                return "PING_INVALID_REQUEST_ERROR"
            case .internalServerError:
                return "PING_INTERNAL_SERVER_ERROR"
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
            case .invalidRequestError:
                return "Ping request was invalid."
            case .internalServerError:
                return "Internal server error during ping."
            case .pingMissingMetadata:
                return "Metadata missing in ping response."
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
            }
        }
    }
}
