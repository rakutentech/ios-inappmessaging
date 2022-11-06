import Foundation

/// Class represents bootstrap behaviour and main functionality of InAppMessaging.
internal class InAppMessagingModule: ErrorDelegate, CampaignDispatcherDelegate, UserChangeObserver {

    private let configurationManager: ConfigurationManagerType
    private let campaignsListManager: CampaignsListManagerType
    private let accountRepository: AccountRepositoryType
    private let eventMatcher: EventMatcherType
    private let readyCampaignDispatcher: CampaignDispatcherType
    private let impressionService: ImpressionServiceType
    private let campaignTriggerAgent: CampaignTriggerAgentType
    private let campaignRepository: CampaignRepositoryType
    private let router: RouterType
    private let randomizer: RandomizerType

    private var isInitialized = false
    private(set) var isEnabled = true
    private var eventBuffer = [Event]()

    var aggregatedErrorHandler: ((NSError) -> Void)?
    var onVerifyContext: ((_ contexts: [String], _ campaignTitle: String) -> Bool)?

    init(configurationManager: ConfigurationManagerType,
         campaignsListManager: CampaignsListManagerType,
         impressionService: ImpressionServiceType,
         accountRepository: AccountRepositoryType,
         eventMatcher: EventMatcherType,
         readyCampaignDispatcher: CampaignDispatcherType,
         campaignTriggerAgent: CampaignTriggerAgentType,
         campaignRepository: CampaignRepositoryType,
         router: RouterType,
         randomizer: RandomizerType,
         displayPermissionService: DisplayPermissionServiceType) {

        self.configurationManager = configurationManager
        self.campaignsListManager = campaignsListManager
        self.accountRepository = accountRepository
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
        displayPermissionService.errorDelegate = self
        self.router.errorDelegate = self
        self.readyCampaignDispatcher.delegate = self
        self.accountRepository.registerAccountUpdateObserver(self)
    }

    // should be called once
    func initialize(completion: @escaping (_ shouldDeinit: Bool) -> Void) {
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
                completion(false)
            } else {
                self.flushEventBuffer(discardEvents: true)
                completion(true)
            }
        }
    }

    func logEvent(_ event: Event) {
        guard isEnabled else {
            return
        }

        guard isInitialized else {
            // Events that were logged after first getConfig request failed,
            // are saved to this list to be processed later
            eventBuffer.append(event)
            return
        }

        checkUserChanges()
        eventMatcher.matchAndStore(event: event)
        campaignTriggerAgent.validateAndTriggerCampaigns()
    }

    func registerPreference(_ preference: UserInfoProvider) {
        guard isEnabled else {
            return
        }

        accountRepository.setPreference(preference)

        guard isInitialized else {
            return
        }

        checkUserChanges()
    }

    func closeMessage(clearQueuedCampaigns: Bool) {
        if clearQueuedCampaigns {
            readyCampaignDispatcher.resetQueue()
        }
        router.discardDisplayedCampaign()
    }

    // visible for testing
    func checkUserChanges() {
        if accountRepository.updateUserInfo() {
            campaignRepository.loadCachedData(syncWithLastUserData: false)
            campaignsListManager.refreshList()
        }
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
        onVerifyContext?(contexts, title) ?? true
    }
}

// MARK: - ErrorDelegate methods
extension InAppMessagingModule {
    func didReceive(error: NSError) {
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

// MARK: - UserChangeObserver
extension InAppMessagingModule {

    func userDidChangeOrLogout() {
        campaignRepository.clearLastUserData()
        eventMatcher.clearNonPersistentEvents()
    }
}
