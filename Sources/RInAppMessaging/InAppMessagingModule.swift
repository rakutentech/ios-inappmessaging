import Foundation

/// Class represents bootstrap behaviour and main functionality of InAppMessaging.
internal class InAppMessagingModule: ErrorDelegate, CampaignDispatcherDelegate, UserChangeObserver, TooltipDispatcherDelegate {

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
         displayPermissionService: DisplayPermissionServiceType,
         tooltipDispatcher: TooltipDispatcherType) {

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
        tooltipDispatcher.delegate = self
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
            self.isInitialized = true

            if enabled {
                self.campaignsListManager.refreshList()
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    /// Stores passed event with matching campaign.
    /// - Parameter event: event to be processed
    /// - Returns: `false` if module is not initialized
    func logEvent(_ event: Event) -> Bool {
        guard isInitialized else {
            return false
        }
        print("IAM Debug: \(Date()) logEvent \(event)")
        checkUserChanges()
        eventMatcher.matchAndStore(event: event)
        campaignTriggerAgent.validateAndTriggerCampaigns()
        return true
    }

    func registerPreference(_ preference: UserInfoProvider) {
        print("IAM Debug: \(Date()) registerPreference()")
        accountRepository.setPreference(preference)

        guard isInitialized else {
            print("IAM Debug: \(Date()) registerPreference() not isInitialized")
            if accountRepository.updateUserInfo() {
                print("IAM Debug: \(Date()) registerPreference() accountRepository.updateUserInfo()")
                campaignRepository.loadCachedData()
            }
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

    func closeTooltip(with uiElementIdentifier: String) {
        router.discardDisplayedTooltip(with: uiElementIdentifier)
    }

    func setAccessibilityCompatibleDisplay(_ flag: Bool) {
        router.accessibilityCompatibleDisplay = flag
    }

    // visible for testing
    func checkUserChanges() {
        print("IAM Debug: \(Date()) checkUserChanges()")
        if accountRepository.updateUserInfo() {
            print("IAM Debug: \(Date()) updateUserInfo()")
            campaignRepository.loadCachedData()
            campaignsListManager.refreshList()
        }
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

// MARK: - TooltipDispatcherDelegate methods
extension InAppMessagingModule {
    
    func shouldShowTooltip(title: String, contexts: [String]) -> Bool {
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
    private func isEnabled(config: ConfigEndpointData) -> Bool {
        guard config.rolloutPercentage > 0 else {
            return false
        }
        return randomizer.dice <= config.rolloutPercentage
    }
}

// MARK: - UserChangeObserver
extension InAppMessagingModule {

    func userDidChangeOrLogout() {
        eventMatcher.clearNonPersistentEvents()
    }
}
