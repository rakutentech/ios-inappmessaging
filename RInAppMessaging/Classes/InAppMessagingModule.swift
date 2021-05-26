/// Class represents bootstrap behaviour and main functionality of InAppMessaging.
internal class InAppMessagingModule: AnalyticsBroadcaster,
    ErrorDelegate, CampaignDispatcherDelegate {

    private var configurationManager: ConfigurationManagerType
    private var campaignsListManager: CampaignsListManagerType
    private let preferenceRepository: IAMPreferenceRepository
    private let eventMatcher: EventMatcherType
    private var readyCampaignDispatcher: CampaignDispatcherType
    private var impressionService: ImpressionServiceType
    private let campaignTriggerAgent: CampaignTriggerAgentType
    private let campaignRepository: CampaignRepositoryType
    private let router: RouterType
    private let randomizer: RandomizerType

    private var isInitialized = false
    private(set) var isEnabled = true
    private var eventBuffer = [Event]()

    var aggregatedErrorHandler: ((NSError) -> Void)?
    weak var delegate: RInAppMessagingDelegate?

    init(configurationManager: ConfigurationManagerType,
         campaignsListManager: CampaignsListManagerType,
         impressionService: ImpressionServiceType,
         preferenceRepository: IAMPreferenceRepository,
         eventMatcher: EventMatcherType,
         readyCampaignDispatcher: CampaignDispatcherType,
         campaignTriggerAgent: CampaignTriggerAgentType,
         campaignRepository: CampaignRepositoryType,
         router: RouterType,
         randomizer: RandomizerType) {

        self.configurationManager = configurationManager
        self.campaignsListManager = campaignsListManager
        self.preferenceRepository = preferenceRepository
        self.eventMatcher = eventMatcher
        self.readyCampaignDispatcher = readyCampaignDispatcher
        self.impressionService = impressionService
        self.campaignTriggerAgent = campaignTriggerAgent
        self.campaignRepository = campaignRepository
        self.router = router
        self.randomizer = randomizer

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
            guard let self = self else {
                return
            }
            let enabled = self.isEnabled(config: config)
            self.isEnabled = enabled
            self.isInitialized = true

            if enabled {
                self.campaignsListManager.refreshList()
                self.flushEventBuffer(discardEvents: false)
            } else {
                self.flushEventBuffer(discardEvents: true)
                deinitHandler()
            }
        }
    }

    func logEvent(_ event: Event) {
        guard isEnabled else {
            return
        }

        sendEventName(Constants.RAnalytics.events, event.analyticsParameters)

        guard isInitialized else {
            // Events that were logged after first getConfig request failed,
            // are saved to this list to be processed later
            eventBuffer.append(event)
            return
        }

        eventMatcher.matchAndStore(event: event)
        campaignTriggerAgent.validateAndTriggerCampaigns()
    }

    func registerPreference(_ preference: IAMPreference?) {
        guard isEnabled else {
            return
        }

        let oldUserIdentifiers = preferenceRepository.getUserIdentifiers()
        let diff = preferenceRepository.preference?.diff(preference)
        preferenceRepository.setPreference(preference)

        guard isInitialized else {
            return
        }

        let isLogoutOrUserChange = (preferenceRepository.getUserIdentifiers().isEmpty || diff?.isEmpty == false) && !oldUserIdentifiers.isEmpty
        if isLogoutOrUserChange {
            campaignRepository.resetDataPersistence()
            eventMatcher.clearNonPersistentEvents()
        }
        campaignRepository.loadCachedData(syncWithLastUserData: false)
        campaignsListManager.refreshList()
    }

    func closeMessage(clearQueuedCampaigns: Bool) {
        if clearQueuedCampaigns {
            readyCampaignDispatcher.resetQueue()
        }
        router.discardDisplayedCampaign()
    }

    private func flushEventBuffer(discardEvents: Bool) {
        if !discardEvents {
            eventBuffer.forEach { event in
                self.eventMatcher.matchAndStore(event: event)
                self.campaignTriggerAgent.validateAndTriggerCampaigns()
            }
        }
        eventBuffer.removeAll()
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

// MARK: - Enabled method
extension InAppMessagingModule {
    private func isEnabled(config: ConfigData) -> Bool {
        guard config.rolloutPercentage > 0 else {
            return false
        }
        return randomizer.dice <= config.rolloutPercentage
    }
}
