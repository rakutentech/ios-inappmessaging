/// Class represents bootstrap behaviour and main functionality of InAppMessaging.
internal class InAppMessagingModule: AnalyticsBroadcaster,
    ErrorDelegate, CampaignDispatcherDelegate {

    private var configurationManager: ConfigurationManagerType
    private var campaignsListManager: CampaignsListManagerType
    private let preferenceRepository: IAMPreferenceRepository
    private let campaignsValidator: CampaignsValidatorType
    private let eventMatcher: EventMatcherType
    private var readyCampaignDispatcher: CampaignDispatcherType
    private var impressionService: ImpressionServiceType
    private let campaignTriggerAgent: CampaignTriggerAgentType
    private let router: RouterType

    private var isInitialized = false
    private var isEnabled = true

    var aggregatedErrorHandler: ((NSError) -> Void)?
    weak var delegate: RInAppMessagingDelegate?

    init(configurationManager: ConfigurationManagerType,
         campaignsListManager: CampaignsListManagerType,
         impressionService: ImpressionServiceType,
         preferenceRepository: IAMPreferenceRepository,
         campaignsValidator: CampaignsValidatorType,
         eventMatcher: EventMatcherType,
         readyCampaignDispatcher: CampaignDispatcherType,
         campaignTriggerAgent: CampaignTriggerAgentType,
         router: RouterType) {

        self.configurationManager = configurationManager
        self.campaignsListManager = campaignsListManager
        self.preferenceRepository = preferenceRepository
        self.campaignsValidator = campaignsValidator
        self.eventMatcher = eventMatcher
        self.readyCampaignDispatcher = readyCampaignDispatcher
        self.impressionService = impressionService
        self.campaignTriggerAgent = campaignTriggerAgent
        self.router = router

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

        let diff = preferenceRepository.preference?.diff(preference)
        preferenceRepository.setPreference(preference)

        guard isInitialized else {
            return
        }

        // clear data only if there was a change in user ids
        if !(diff == nil || diff == [] || diff == [.accessToken]) {
            let isLogout = preference == nil
            // we leave triggered persistent event only campaigns untouched
            // so they won't be displayed again immediately after logout (only after login)
            eventMatcher.clearStoredData(nonPersistentEventsOnly: isLogout)
            router.discardDisplayedCampaign()
        }
        campaignsListManager.refreshList()
    }
}

// MARK: - CampaignDispatcherDelegate methods
extension InAppMessagingModule {

    func performPing() {
        DispatchWorkItem(qos: .utility, flags: []) {
            self.campaignsListManager.refreshList()
        }.perform()
    }

    func shouldShowCampaignMessage(title: String, contexts: [String]) -> Bool {
        guard let delegate = delegate else {
            return true
        }
        return delegate.inAppMessagingShouldShowCampaignWithContexts(contexts: contexts,
                                                                     campaignTitle: title)
    }
}

// MARK: - ErrorDelegate methods
extension InAppMessagingModule {
    func didReceiveError(sender: ErrorReportable, error: NSError) {
        aggregatedErrorHandler?(error)
    }
}
