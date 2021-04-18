import Foundation

internal protocol ConfigurationManagerType: AnyObject, ErrorReportable {
    func fetchAndSaveConfigData(completion: @escaping (ConfigData) -> Void)
}

internal class ConfigurationManager: ConfigurationManagerType {
    private let configurationService: ConfigurationServiceType
    private let configurationRepository: ConfigurationRepositoryType
    private let reachability: ReachabilityType?
    private let resumeQueue: DispatchQueue

    private var retryDelayMS = Constants.Retry.Default.initialRetryDelayMS
    private var lastRequestTime: TimeInterval = 0
    private var onConnectionResumed: (() -> Void)?

    weak var errorDelegate: ErrorDelegate?
    private(set) var scheduledTask: DispatchWorkItem?

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
            reportError(description: "Error calling config server. Retrying in \(retryDelayMS)ms", data: error)
            switch error {
            case ConfigurationServiceError.tooManyRequestsError:
                if case ResponseState.success = previousState {
                    retryDelayMS = Constants.Retry.TooManyRequestsError.initialRetryDelayMS
                }
                scheduledTask = WorkScheduler.scheduleTask(milliseconds: Int(retryDelayMS), closure: retryHandler, wallDeadline: true)
                // Exponential backoff for pinging Configuration server.
                retryDelayMS.increaseRandomizedBackoff()

            default:
                scheduledTask = WorkScheduler.scheduleTask(milliseconds: Int(retryDelayMS), closure: retryHandler, wallDeadline: true)
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
