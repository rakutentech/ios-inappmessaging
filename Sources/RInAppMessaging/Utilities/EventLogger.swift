import Foundation

#if canImport(RSDKUtilsMain)
import RSDKUtilsMain // SPM version
import REventLogger // SPM version
#else
import RSDKUtils
#endif

protocol EventLoggerSendable {
    var isEventLoggerEnabled: Bool { get set }
    func configure(apiKey: String?, apiUrl: String?, isEventLoggerEnabled: Bool?)
    func logEvent(eventType: REventType, errorCode: String, errorMessage: String)
}

final class EventLogger: EventLoggerSendable {
    var isEventLoggerEnabled = true

    func configure(apiKey: String?, apiUrl: String?, isEventLoggerEnabled: Bool?)
    {
        self.isEventLoggerEnabled = isEventLoggerEnabled ?? false
        guard self.isEventLoggerEnabled else { return }

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
