internal protocol CampaignsListManagerType: ErrorReportable {
    func refreshList()
}

internal class CampaignsListManager: CampaignsListManagerType, TaskSchedulable {

    private enum Constants {
        static let initialRetryDelayMS = Int32(10000)
    }

    private var campaignRepository: CampaignRepositoryType
    private let campaignTriggerAgent: CampaignTriggerAgentType
    private let messageMixerService: MessageMixerServiceType

    weak var errorDelegate: ErrorDelegate?
    var scheduledTask: DispatchWorkItem?
    private var retryDelayMS = Constants.initialRetryDelayMS

    init(campaignRepository: CampaignRepositoryType,
         campaignTriggerAgent: CampaignTriggerAgentType,
         messageMixerService: MessageMixerServiceType) {

        self.campaignRepository = campaignRepository
        self.campaignTriggerAgent = campaignTriggerAgent
        self.messageMixerService = messageMixerService
    }

    func refreshList() {
        pingMixerServer()
    }

    private func pingMixerServer() {

        let pingResult = messageMixerService.ping()
        let decodedResponse: PingResponse
        do {
            decodedResponse = try pingResult.get()
        } catch {
            handleError(error)
            return
        }

        retryDelayMS = Constants.initialRetryDelayMS

        CommonUtility.lock(resourcesIn: [campaignRepository]) {
            campaignRepository.syncWith(list: decodedResponse.data,
                                        timestampMilliseconds: decodedResponse.currentPingMilliseconds)
        }
        campaignTriggerAgent.validateAndTriggerCampaigns()

        scheduleNextPingCall(in: decodedResponse.nextPingMilliseconds)
    }

    private func handleError(_ error: Error) {
        switch error {
        case MessageMixerServiceError.invalidConfiguration:
            reportError(description: "Error retrieving InAppMessaging Mixer Server URL", data: nil)

        case MessageMixerServiceError.jsonDecodingError(let decodingError):
            reportError(description: "Failed to parse json", data: decodingError)

        default:
            scheduleNextPingCall(in: Int(retryDelayMS))
            // Exponential backoff for pinging Message Mixer server.
            retryDelayMS = retryDelayMS.multipliedReportingOverflow(by: 2).partialValue
        }
    }

    private func scheduleNextPingCall(in milliseconds: Int) {
        scheduleWorkItem(milliseconds: milliseconds, wallDeadline: true) { [weak self] in
            self?.pingMixerServer()
        }
    }
}
