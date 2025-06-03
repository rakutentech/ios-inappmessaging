import Foundation
#if SWIFT_PACKAGE
import RSDKUtilsMain
#else
import RSDKUtils
#endif

protocol EventLoggerSendable {
    func configure()
    func logEvent(eventType: REventType, errorCode: String, errorMessage: String, info: [String: String]?)
    func setLoggerApiConfig(apiKey: String, apiUrl: String)
}

class EventLogger: EventLoggerSendable {
    private var apiKey: String?
    private var apiUrl: String?

    init() {
        // Custom no-argument initializer
    }

    func setLoggerApiConfig(apiKey: String, apiUrl: String) {
        self.apiKey = apiKey
        self.apiUrl = apiUrl
    }

    func configure() {
        guard let apiKey = apiKey, let apiUrl = apiUrl else {
            return
        }
        REventLogger.shared.configure(apiKey: apiKey, apiUrl: apiUrl)
    }

    func logEvent(eventType: REventType, errorCode: String, errorMessage: String, info: [String: String]? = nil) {
        
        if eventType == REventType.critical {
            REventLogger.shared.sendCriticalEvent(sourceName: "iam",
                                                  sourceVersion: Constants.Versions.sdkVersion,
                                                  errorCode: errorCode, errorMessage: errorMessage)
        } else {
            REventLogger.shared.sendWarningEvent(sourceName: "iam",
                                                 sourceVersion: Constants.Versions.sdkVersion,
                                                 errorCode: errorCode, errorMessage: errorMessage)
        }
    }
}

enum REventType {
    case critical
    case warning
}
