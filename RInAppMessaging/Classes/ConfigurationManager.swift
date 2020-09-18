import Foundation

internal protocol ConfigurationManagerType: AnyObject, ErrorReportable {
    func fetchAndSaveConfigData(completion: @escaping (ConfigData) -> Void)
}

internal class ConfigurationManager: ConfigurationManagerType {

    private enum Constants {
        static let initialRetryDelayMS = Int32(10000)
    }

    private let configurationService: ConfigurationServiceType
    private let configurationRepository: ConfigurationRepositoryType
    private let reachability: ReachabilityType?
    private let resumeQueue: DispatchQueue

    private var retryDelayMS = Constants.initialRetryDelayMS
    private var lastRequestTime: TimeInterval = 0
    private var onConnectionResumed: (() -> Void)?

    weak var errorDelegate: ErrorDelegate?

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
            retryDelayMS = Constants.initialRetryDelayMS

            configurationRepository.saveConfiguration(configData)
            completion(configData)

        case .failure(let error):
            reportError(description: "Error calling config server. Retrying in \(retryDelayMS)ms", data: error)
            WorkScheduler.scheduleTask(milliseconds: Int(retryDelayMS), closure: retryHandler, wallDeadline: true)
            // Exponential backoff for pinging Configuration server.
            retryDelayMS = retryDelayMS.multipliedReportingOverflow(by: 2).partialValue
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
