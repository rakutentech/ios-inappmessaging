import Foundation
import RSDKUtils

protocol EventLoggerSendable {
    func configure(apiKey: String, apiUrl: String)
    func logEvent(eventType: REventType, errorCode: String, errorMessage: String, info: [String: String]?)
}

class EventLogger: EventLoggerSendable {
    init() {
        // Custom no-argument initializer
    }
    
    func configure(apiKey: String, apiUrl: String) {
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
