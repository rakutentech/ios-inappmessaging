import Foundation

#if SWIFT_PACKAGE
import RSDKUtilsMain
#else
import RSDKUtils
#endif

internal protocol ConfigurationManagerType: ErrorReportable {
    func fetchAndSaveConfigData(completion: @escaping (ConfigEndpointData) -> Void)
    func save(moduleConfig config: InAppMessagingModuleConfiguration)
}

internal class ConfigurationManager: ConfigurationManagerType, TaskSchedulable {
    private let configurationService: ConfigurationServiceType?
    private let configurationRepository: ConfigurationRepositoryType
    private let reachability: ReachabilityType?
    private let resumeQueue: DispatchQueue
    // lazy allows mocking in unit tests
    private lazy var retryDelayMS = Constants.Retry.Default.initialRetryDelayMS
    private var lastRequestTime: TimeInterval = 0
    private var onConnectionResumed: (() -> Void)?
    private var responseStateMachine = ResponseStateMachine()
    private let eventLogger: EventLoggerSendable
    
    var scheduledTask: DispatchWorkItem?
    weak var errorDelegate: ErrorDelegate?

    init(reachability: ReachabilityType?,
         configurationService: ConfigurationServiceType?,
         configurationRepository: ConfigurationRepositoryType,
         resumeQueue: DispatchQueue,
         eventLogger: EventLoggerSendable) {

        self.reachability = reachability
        self.configurationService = configurationService
        self.configurationRepository = configurationRepository
        self.resumeQueue = resumeQueue
        self.eventLogger = eventLogger
    }

    deinit {
        scheduledTask?.cancel()
    }

    func fetchAndSaveConfigData(completion: @escaping (ConfigEndpointData) -> Void) {
        guard let configurationService = configurationService else {
            reportError(description: "Configuration URL in Info.plist is missing. IAM SDK will be disabled.", data: nil)
            completion(ConfigEndpointData(rolloutPercentage: 0, endpoints: nil))
            return
        }
        let retryHandler: () -> Void = { [weak self] in
            self?.fetchAndSaveConfigData(completion: completion)
        }

        if let reachability = reachability, !reachability.connection.isAvailable {
            onConnectionResumed = retryHandler
            reachability.addObserver(self)
            return
        }

        let result = configurationService.getConfigData()
        switch result {
        case .success(let configData):
            responseStateMachine.push(state: .success)
            retryDelayMS = Constants.Retry.Default.initialRetryDelayMS

            configurationRepository.saveRemoteConfiguration(configData)
            completion(configData)

        case .failure(let error):
            responseStateMachine.push(state: .error)

            switch error {
            case .missingOrInvalidConfigURL:
                eventLogger.logEvent(eventType: .critical, errorCode: Constants.IAMErrorCode.configInvalidConfigUrl.errorCode, errorMessage: Constants.IAMErrorCode.configInvalidConfigUrl.errorMessage)
                reportError(
                    description: "Invalid Configuration URL: \(configurationRepository.getConfigEndpointURLString() ?? "<empty>"). SDK will be disabled.",
                    data: error)
                
                completion(ConfigEndpointData(rolloutPercentage: 0, endpoints: nil))

            case .tooManyRequestsError:
                scheduleRetryWithRandomizedBackoff(retryHandler: retryHandler)

            case .missingOrInvalidSubscriptionId:
                eventLogger.logEvent(eventType: .critical, errorCode: Constants.IAMErrorCode.configMissingOrInvalidSubscriptionId.errorCode, errorMessage: Constants.IAMErrorCode.configMissingOrInvalidSubscriptionId.errorMessage)
                reportError(description: "Config request error: Missing or invalid Subscription ID. SDK will be disabled.", data: error)
                completion(ConfigEndpointData(rolloutPercentage: 0, endpoints: nil))

            case .unknownSubscriptionId:
                eventLogger.logEvent(eventType: .critical, errorCode: Constants.IAMErrorCode.configUnknownSubscriptionId.errorCode, errorMessage: Constants.IAMErrorCode.configUnknownSubscriptionId.errorMessage)
                reportError(description: "Config request error: Unknown Subscription ID. SDK will be disabled.", data: error)
                completion(ConfigEndpointData(rolloutPercentage: 0, endpoints: nil))

            case .internalServerError(let code):
                guard responseStateMachine.consecutiveErrorCount <= Constants.Retry.retryCount else {
                    eventLogger.logEvent(eventType: .critical, errorCode: Constants.IAMErrorCode.configInternalServerError.errorCode + String(code), errorMessage: Constants.IAMErrorCode.configInternalServerError.errorMessage)
                    reportError(description: "Config request error: Response Code \(code): Internal server error", data: nil)
                    completion(ConfigEndpointData(rolloutPercentage: 0, endpoints: nil))
                    return
                }
                scheduleRetryWithRandomizedBackoff(retryHandler: retryHandler)
                eventLogger.logEvent(eventType: .critical, errorCode: Constants.IAMErrorCode.configInternalServerError.errorCode + String(code), errorMessage: Constants.IAMErrorCode.configInternalServerError.errorMessage)
                reportError(description: "Config request error: Response Code \(code): Internal server error. Retry scheduled", data: nil)

            case .invalidRequestError(let code):
                eventLogger.logEvent(eventType: .critical, errorCode: Constants.IAMErrorCode.configInvalidRequestError.errorCode + String(code), errorMessage: Constants.IAMErrorCode.configInvalidRequestError.errorMessage)
                reportError(description: "Config request error: Response Code \(code): Invalid request error", data: nil)
                completion(ConfigEndpointData(rolloutPercentage: 0, endpoints: nil))

            case .jsonDecodingError(let decodingError):
                eventLogger.logEvent(eventType: .critical, errorCode: Constants.IAMErrorCode.configJsonDecodingError.errorCode, errorMessage: Constants.IAMErrorCode.configJsonDecodingError.errorMessage)
                reportError(description: "Config request error: Failed to parse json", data: decodingError)
                completion(ConfigEndpointData(rolloutPercentage: 0, endpoints: nil))

            default:
                reportError(description: "Error calling config server. Retrying in \(retryDelayMS)ms", data: error)
                scheduleTask(milliseconds: Int(retryDelayMS), wallDeadline: true, retryHandler)
                // Exponential backoff for pinging Configuration server.
                retryDelayMS.increaseBackOff()
            }
        }
    }

    func save(moduleConfig config: InAppMessagingModuleConfiguration) {
        configurationRepository.saveIAMModuleConfiguration(config)
    }

    private func scheduleRetryWithRandomizedBackoff(retryHandler: @escaping () -> Void) {
        if responseStateMachine.consecutiveErrorCount <= 1 {
            retryDelayMS = Constants.Retry.Randomized.initialRetryDelayMS
        }
        scheduleTask(milliseconds: Int(retryDelayMS), wallDeadline: true, retryHandler)
        // Randomized backoff for Configuration server.
        retryDelayMS.increaseRandomizedBackoff()
    }
}

// MARK: - ReachabilityObserver

extension ConfigurationManager: ReachabilityObserver {
    func reachabilityChanged(_ reachability: ReachabilityType) {
        guard let onConnectionResumed = onConnectionResumed,
            reachability.connection.isAvailable else {
                return
        }

        reachability.removeObserver(self)
        self.onConnectionResumed = nil

        resumeQueue.async(flags: .barrier) {
            onConnectionResumed()
        }
    }
}
