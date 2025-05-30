import Foundation
import RSDKUtils

public protocol EventLoggerConfigurationProvider {
    var apiKey: String { get }
    var apiUrl: String { get }
}

protocol EventLoggerSendable {
    func configure(apiKey: String, apiUrl: String)
    func logEvent(eventType: REventType, errorCode: String, errorMessage: String, info: [String: String]?)
}

class EventLogger: EventLoggerSendable {
    private let rmcConfiguration: EventLoggerConfigurationProvider

    init(rmcConfiguration: EventLoggerConfigurationProvider) {
        self.rmcConfiguration = rmcConfiguration
    }
    func configure(apiKey: String, apiUrl: String) {
        REventLogger.shared.configure(apiKey: rmcConfiguration.apiKey, apiUrl: rmcConfiguration.apiUrl)
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
