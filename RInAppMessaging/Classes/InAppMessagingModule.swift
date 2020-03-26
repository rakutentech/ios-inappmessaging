/// Class represents bootstrap behaviour and main functionality of InAppMessaging.
internal class InAppMessagingModule: AnalyticsBroadcaster,
    ErrorDelegate, ReadyCampaignDispatcherDelegate {

    private var configurationManager: ConfigurationManagerType
    private var campaignsListManager: CampaignsListManagerType
    private let preferenceRepository: IAMPreferenceRepository
    private let campaignsValidator: CampaignsValidatorType
    private let eventMatcher: EventMatcherType
    private var readyCampaignDispatcher: ReadyCampaignDispatcherType
    private var impressionService: ImpressionServiceType
    private let campaignTriggerAgent: CampaignTriggerAgentType

    private var isInitialized = false
    private var isEnabled = true

    var aggregatedErrorHandler: ((NSError) -> Void)?

    init(configurationManager: ConfigurationManagerType,
         campaignsListManager: CampaignsListManagerType,
         impressionService: ImpressionServiceType,
         preferenceRepository: IAMPreferenceRepository,
         campaignsValidator: CampaignsValidatorType,
         eventMatcher: EventMatcherType,
         readyCampaignDispatcher: ReadyCampaignDispatcherType,
         campaignTriggerAgent: CampaignTriggerAgentType) {

        self.configurationManager = configurationManager
        self.campaignsListManager = campaignsListManager
        self.preferenceRepository = preferenceRepository
        self.campaignsValidator = campaignsValidator
        self.eventMatcher = eventMatcher
        self.readyCampaignDispatcher = readyCampaignDispatcher
        self.impressionService = impressionService
        self.campaignTriggerAgent = campaignTriggerAgent

        self.configurationManager.errorDelegate = self
        self.campaignsListManager.errorDelegate = self
        self.impressionService.errorDelegate = self
        self.readyCampaignDispatcher.delegate = self
    }

    // should be called once
    func initialize(deinitHandler: @escaping () -> Void) {
        guard !isInitialized else {
            return
        }

        configurationManager.fetchAndSaveConfigData { [weak self] config in
            self?.isEnabled = config.enabled
            self?.isInitialized = true

            if config.enabled {
                self?.campaignsListManager.refreshList()
            } else {
                deinitHandler()
            }
        }
    }

    func logEvent(_ event: Event) {
        guard isEnabled else {
            return
        }

        eventMatcher.matchAndStore(event: event)
        sendEventName(Constants.RAnalytics.events, event.analyticsParameters)

        guard isInitialized else {
            return
        }

        campaignsValidator.validate { campaign, events in
            campaignTriggerAgent.trigger(campaign: campaign, triggeredEvents: events)
        }
        readyCampaignDispatcher.dispatchAllIfNeeded()
    }

    func registerPreference(_ preference: IAMPreference?) {
        guard isEnabled else {
            return
        }

        preferenceRepository.setPreference(preference)

        guard isInitialized else {
            return
        }

        campaignsListManager.refreshList()
    }
}

// MARK: - ReadyCampaignDispatcherDelegate methods
extension InAppMessagingModule {
    func performPing() {
        campaignsListManager.refreshList()
    }
}

// MARK: - ErrorDelegate methods
extension InAppMessagingModule {
    func didReceiveError(sender: ErrorReportable, error: NSError) {
        aggregatedErrorHandler?(error)
    }
}
