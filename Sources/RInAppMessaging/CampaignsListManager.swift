import Foundation

internal protocol CampaignsListManagerType: ErrorReportable {
    func refreshList()
}

internal class CampaignsListManager: CampaignsListManagerType, TaskSchedulable {

    private var campaignRepository: CampaignRepositoryType
    private let campaignTriggerAgent: CampaignTriggerAgentType
    private let pingService: PingServiceType
    private let configurationRepository: ConfigurationRepositoryType

    weak var errorDelegate: ErrorDelegate?
    var scheduledTask: DispatchWorkItem?
    // lazy allows mocking in unit tests
    private lazy var retryDelayMS = Constants.Retry.Default.initialRetryDelayMS
    private var responseStateMachine = ResponseStateMachine()
    private let pingQueue = DispatchQueue(label: "IAM.Ping", qos: .utility)

    init(campaignRepository: CampaignRepositoryType,
         campaignTriggerAgent: CampaignTriggerAgentType,
         pingService: PingServiceType,
         configurationRepository: ConfigurationRepositoryType) {

        self.campaignRepository = campaignRepository
        self.campaignTriggerAgent = campaignTriggerAgent
        self.pingService = pingService
        self.configurationRepository = configurationRepository
    }

    deinit {
        self.scheduledTask?.cancel()
    }

    func refreshList() {
        pingQueue.sync {
            pingMixerServer()
        }
    }

    private func pingMixerServer() {
        guard scheduledTask == nil || responseStateMachine.previousState == .success else {
            // ping request is already queued (errors only)
            return
        }

        let pingResult = pingService.ping()
        let decodedResponse: PingResponse
        do {
            decodedResponse = try pingResult.get()
        } catch {
            handleError(error)
            return
        }
        handleSuccess(decodedResponse)
    }

    private func handleSuccess(_ decodedResponse: PingResponse) {
        responseStateMachine.push(state: .success)
        retryDelayMS = Constants.Retry.Default.initialRetryDelayMS

        CommonUtility.lock(resourcesIn: [campaignRepository]) {
            campaignRepository.syncWith(list: decodedResponse.data,
                                        timestampMilliseconds: decodedResponse.currentPingMilliseconds,
                                        ignoreTooltips: !configurationRepository.isTooltipFeatureEnabled)
        }
        campaignTriggerAgent.validateAndTriggerCampaigns()

        scheduleNextPingCall(in: decodedResponse.nextPingMilliseconds)
    }

    private func handleError(_ error: Error) {
        responseStateMachine.push(state: .error)

        switch error {
        case PingServiceError.invalidConfiguration:
            reportError(description: "Error retrieving InAppMessaging Mixer Server URL", data: nil)

        case PingServiceError.jsonDecodingError(let decodingError):
            reportError(description: "Ping request error: Failed to parse json", data: decodingError)

        case PingServiceError.tooManyRequestsError:
            scheduleNextPingCallWithRandomizedBackoff()

        case PingServiceError.internalServerError(let code):
            guard responseStateMachine.consecutiveErrorCount <= Constants.Retry.retryCount else {
                reportError(description: "Ping request error: Response Code \(code): Internal server error", data: nil)
                return
            }
            scheduleNextPingCallWithRandomizedBackoff()
            reportError(description: "Ping request error: Response Code \(code): Internal server error. Retry scheduled", data: nil)

        case PingServiceError.invalidRequestError(let code):
            reportError(description: "Ping request error: Response Code \(code): Invalid request error", data: nil)

        default:
            reportError(description: error.localizedDescription + ", Retrying in \(Int(retryDelayMS))ms", data: nil)
            scheduleNextPingCall(in: Int(retryDelayMS))
            // Exponential backoff for pinging Message Mixer server.
            retryDelayMS.increaseBackOff()
        }
    }

    private func scheduleNextPingCallWithRandomizedBackoff() {
        if responseStateMachine.consecutiveErrorCount <= 1 {
            retryDelayMS = Constants.Retry.Randomized.initialRetryDelayMS
        }
        scheduleNextPingCall(in: Int(retryDelayMS))
        // Randomized backoff for pinging Message Mixer server.
        retryDelayMS.increaseRandomizedBackoff()
    }

    private func scheduleNextPingCall(in milliseconds: Int) {
        scheduleTask(milliseconds: milliseconds, wallDeadline: true) { [weak self] in
            self?.pingQueue.sync {
                self?.pingMixerServer()
            }
        }
    }
}
