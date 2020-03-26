internal protocol CampaignsListManagerType: ErrorReportable {
    func refreshList()
}

internal class CampaignsListManager: CampaignsListManagerType, TaskSchedulable {

    private enum Constants {
        static let initialRetryDelayMS = Int32(10000)
    }

    private let campaignsValidator: CampaignsValidatorType
    private var campaignRepository: CampaignRepositoryType
    private let readyCampaignDispatcher: ReadyCampaignDispatcherType
    private let campaignTriggerAgent: CampaignTriggerAgentType
    private let messageMixerService: MessageMixerServiceType

    weak var errorDelegate: ErrorDelegate?
    var scheduledTask: DispatchWorkItem?
    private var retryDelayMS = Constants.initialRetryDelayMS

    init(campaignsValidator: CampaignsValidatorType,
         campaignRepository: CampaignRepositoryType,
         readyCampaignDispatcher: ReadyCampaignDispatcherType,
         campaignTriggerAgent: CampaignTriggerAgentType,
         messageMixerService: MessageMixerServiceType) {

        self.campaignsValidator = campaignsValidator
        self.campaignRepository = campaignRepository
        self.readyCampaignDispatcher = readyCampaignDispatcher
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
                                        timestampMilliseconds: decodedResponse.currentPingMillis)
        }
        campaignsValidator.validate { campaign, events in
            campaignTriggerAgent.trigger(campaign: campaign, triggeredEvents: events)
        }

        readyCampaignDispatcher.dispatchAllIfNeeded()

        scheduleNextPingCall(in: decodedResponse.nextPingMillis)
    }

    private func handleError(_ error: Error) {
        switch error {
        case MessageMixerServiceError.invalidConfiguration:
            let error = "InAppMessaging: Error retrieving InAppMessaging Mixer Server URL"
            CommonUtility.debugPrint(error)
            reportError(description: error, data: nil)

        case MessageMixerServiceError.jsonDecodingError(let decodingError):
            let description = "InAppMessaging: Failed to parse json"
            CommonUtility.debugPrint("\(description): \(decodingError)")
            reportError(description: description, data: decodingError)

        default:
            scheduleNextPingCall(in: Int(retryDelayMS))
            // Exponential backoff for pinging Message Mixer server.
            retryDelayMS = retryDelayMS.multipliedReportingOverflow(by: 2).partialValue
        }
    }

    private func scheduleNextPingCall(in milliseconds: Int) {
        scheduleWorkItem(milliseconds: milliseconds,
                         task: DispatchWorkItem { self.pingMixerServer() },
                         wallDeadline: true)
    }
}
