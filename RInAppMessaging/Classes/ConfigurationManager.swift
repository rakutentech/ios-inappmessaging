import Foundation

internal protocol ConfigurationManagerType: AnyObject, ErrorReportable {
    func fetchAndSaveConfigData(completion: @escaping (ConfigData) -> Void)
}

internal class ConfigurationManager: ConfigurationManagerType, TaskSchedulable {
    private let configurationService: ConfigurationServiceType
    private let configurationRepository: ConfigurationRepositoryType
    private let reachability: ReachabilityType?
    private let resumeQueue: DispatchQueue

    private var retryDelayMS = Constants.Retry.Default.initialRetryDelayMS
    private var lastRequestTime: TimeInterval = 0
    private var onConnectionResumed: (() -> Void)?

    var scheduledTask: DispatchWorkItem?
    weak var errorDelegate: ErrorDelegate?

    private var state = ResponseState.success
    private var previousState = ResponseState.success

    init(reachability: ReachabilityType?,
         configurationService: ConfigurationServiceType,
         configurationRepository: ConfigurationRepositoryType,
         resumeQueue: DispatchQueue) {

        self.reachability = reachability
        self.configurationService = configurationService
        self.configurationRepository = configurationRepository
        self.resumeQueue = resumeQueue
    }

    deinit {
        scheduledTask?.cancel()
    }

    func fetchAndSaveConfigData(completion: @escaping (ConfigData) -> Void) {
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
            previousState = state
            state = ResponseState.success
            retryDelayMS = Constants.Retry.Default.initialRetryDelayMS

            configurationRepository.saveConfiguration(configData)
            completion(configData)

        case .failure(let error):
            previousState = state
            state = ResponseState.error(error)

            switch error {
            case .tooManyRequestsError:
                reportError(description: "Error calling config server. Retrying in \(retryDelayMS)ms", data: error)
                if case ResponseState.success = previousState {
                    retryDelayMS = Constants.Retry.TooManyRequestsError.initialRetryDelayMS
                }
                scheduleTask(milliseconds: Int(retryDelayMS), wallDeadline: true, retryHandler)
                // Exponential backoff for pinging Configuration server.
                retryDelayMS.increaseRandomizedBackoff()
            case .missingOrInvalidSubscriptionId:
                reportError(description: "Config request error: Missing or invalid Subscription ID. SDK will be disabled.", data: error)
                completion(ConfigData(rolloutPercentage: 0, endpoints: nil))
            case .unknownSubscriptionId:
                reportError(description: "Config request error: Unknown Subscription ID. SDK will be disabled.", data: error)
                completion(ConfigData(rolloutPercentage: 0, endpoints: nil))

            default:
                reportError(description: "Error calling config server. Retrying in \(retryDelayMS)ms", data: error)
                scheduleTask(milliseconds: Int(retryDelayMS), wallDeadline: true, retryHandler)
                // Exponential backoff for pinging Configuration server.
                retryDelayMS.increaseBackOff()
            }
        }
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
