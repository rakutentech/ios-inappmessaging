import Foundation

#if canImport(RSDKUtils)
import RSDKUtils
#elseif canImport(RSDKUtilsMain)
import RSDKUtilsMain
#endif

protocol EventLoggerSendable {
    var isEventLoggerEnabled: Bool { get set }
    func configure()
    func logEvent(eventType: REventType, errorCode: String, errorMessage: String)
    func setupApiConfig(apiKey: String, apiUrl: String, isEventLoggerEnabled: Bool)
}

final class EventLogger: EventLoggerSendable {
    var isEventLoggerEnabled = true
    private var apiKey: String?
    private var apiUrl: String?

    func setupApiConfig(apiKey: String, apiUrl: String, isEventLoggerEnabled: Bool) {
        self.apiKey = apiKey
        self.apiUrl = apiUrl
        self.isEventLoggerEnabled = isEventLoggerEnabled
    }

    func configure() {
        guard isEventLoggerEnabled else { return }
        guard let apiKey = apiKey, let apiUrl = apiUrl else {
            return
        }
        REventLogger.shared.configure(apiKey: apiKey, apiUrl: apiUrl)
    }

    func logEvent(eventType: REventType, errorCode: String, errorMessage: String) {
        guard isEventLoggerEnabled  else { return }
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
