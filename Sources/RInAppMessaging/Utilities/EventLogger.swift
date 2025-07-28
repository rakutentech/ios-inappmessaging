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
    func setEventInfoHandler(handler: ((Int, String, String, [String: String]?) -> Void)?)
}

final class EventLogger: EventLoggerSendable {
    var isEventLoggerEnabled = true
    private var eventInfoHandler: ((Int, String, String, [String: String]?) -> Void)?

    func configure(apiKey: String?, apiUrl: String?, isEventLoggerEnabled: Bool?) {
        self.isEventLoggerEnabled = isEventLoggerEnabled ?? false
        guard self.isEventLoggerEnabled else { return }

        guard let apiKey = apiKey, let apiUrl = apiUrl else {
            return
        }
        REventLogger.shared.configure(apiKey: apiKey, apiUrl: apiUrl, appGroupId: " ")
    }

    func logEvent(eventType: REventType, errorCode: String, errorMessage: String) {
        if RInAppMessaging.isRMCEnvironment {
            eventInfoHandler?(eventType.rawValue, errorCode, errorMessage, nil)
            return
        }

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

    func setEventInfoHandler(handler: ((Int, String, String, [String: String]?) -> Void)?) {
        self.eventInfoHandler = handler
    }
}

enum REventType: Int {
    case critical
    case warning
}
