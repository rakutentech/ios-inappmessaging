import Foundation

#if SWIFT_PACKAGE
import RSDKUtilsMain
#else
import RSDKUtils
#endif


/// Class that handles API calls that are interacting with InAppMessagingModule instance.
/// Its role is to retain the SDK settings and logged events prior calling `configure()`.
/// All waiting information gets processed once InAppMessagingModule initialization finishes.
final class InAppMessagingInteractor {

    var iamModule: InAppMessagingModule?
    var accessibilityCompatibleDisplay = false {
        didSet {
            iamModule?.setAccessibilityCompatibleDisplay(accessibilityCompatibleDisplay)
        }
    }
    var onVerifyContext: ((_ contexts: [String], _ campaignTitle: String) -> Bool)? {
        didSet {
            iamModule?.onVerifyContext = onVerifyContext
        }
    }
    var errorCallback: ((NSError) -> Void)? {
        didSet {
            iamModule?.aggregatedErrorHandler = errorCallback
        }
    }
    var userPerference: UserInfoProvider? {
        didSet {
            guard let userPerference else {
                return
            }
            print("IAM Debug: \(Date()) registerPreference() userPerference")
            iamModule?.registerPreference(userPerference)
        }
    }
    private var eventBuffer = [Event]()

    func configure(dependencyManager: TypedDependencyManager,
                   moduleConfig: InAppMessagingModuleConfiguration,
                   completion: @escaping (Bool) -> Void) {
        guard iamModule == nil else {
            return
        }

        guard let configurationManager = dependencyManager.resolve(type: ConfigurationManagerType.self),
              let campaignsListManager = dependencyManager.resolve(type: CampaignsListManagerType.self),
              let impressionService = dependencyManager.resolve(type: ImpressionServiceType.self),
              let eventMatcher = dependencyManager.resolve(type: EventMatcherType.self),
              let accountRepository = dependencyManager.resolve(type: AccountRepositoryType.self),
              let readyCampaignDispatcher = dependencyManager.resolve(type: CampaignDispatcherType.self),
              let campaignTriggerAgent = dependencyManager.resolve(type: CampaignTriggerAgentType.self),
              let campaignRepository = dependencyManager.resolve(type: CampaignRepositoryType.self),
              let router = dependencyManager.resolve(type: RouterType.self),
              let randomizer = dependencyManager.resolve(type: Randomizer.self),
              let displayPermissionService = dependencyManager.resolve(type: DisplayPermissionServiceType.self),
              let viewListener = dependencyManager.resolve(type: ViewListenerType.self),
              let _ = dependencyManager.resolve(type: TooltipEventSenderType.self),
              let tooltipDispatcher = dependencyManager.resolve(type: TooltipDispatcherType.self) else {

            assertionFailure("In-App Messaging SDK module initialization failure: Dependencies could not be resolved")
            return
        }
        router.accessibilityCompatibleDisplay = accessibilityCompatibleDisplay
        configurationManager.save(moduleConfig: moduleConfig)

        let module = InAppMessagingModule(configurationManager: configurationManager,
                                          campaignsListManager: campaignsListManager,
                                          impressionService: impressionService,
                                          accountRepository: accountRepository,
                                          eventMatcher: eventMatcher,
                                          readyCampaignDispatcher: readyCampaignDispatcher,
                                          campaignTriggerAgent: campaignTriggerAgent,
                                          campaignRepository: campaignRepository,
                                          router: router,
                                          randomizer: randomizer,
                                          displayPermissionService: displayPermissionService,
                                          tooltipDispatcher: tooltipDispatcher)
        module.aggregatedErrorHandler = errorCallback
        module.onVerifyContext = onVerifyContext
        module.setAccessibilityCompatibleDisplay(accessibilityCompatibleDisplay)
        if let userPerference {
            print("IAM Debug: \(Date()) registerPreference() userPerference configure()")
            module.registerPreference(userPerference)
        }
        iamModule = module
        iamModule?.initialize { [weak self] shouldDeinit in
            if shouldDeinit {
                self?.iamModule = nil
                viewListener.stopListening()
                self?.flushEventBuffer(discardEvents: true)

            } else if moduleConfig.isTooltipFeatureEnabled {
                viewListener.startListening()
            }

            self?.flushEventBuffer(discardEvents: false)
            completion(shouldDeinit)
        }
    }

    func logEvent(_ event: Event) {
        let didLogEvent = iamModule?.logEvent(event) == true
        if !didLogEvent {
            eventBuffer.append(event)
        }
    }

    func closeMessage(clearQueuedCampaigns: Bool) {
        iamModule?.closeMessage(clearQueuedCampaigns: clearQueuedCampaigns)
    }

    func closeTooltip(with uiElementIdentifier: String) {
        iamModule?.closeTooltip(with: uiElementIdentifier)
    }

    private func flushEventBuffer(discardEvents: Bool) {
        if !discardEvents {
            eventBuffer.forEach(logEvent)
        }
        eventBuffer.removeAll()
    }
}
