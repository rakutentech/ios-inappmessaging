/// Protocol for optional delagate
@objc public protocol RInAppMessagingDelegate: AnyObject {
    /// Method called only for campaigns with context just before displaying its message
    func inAppMessagingShouldShowCampaignWithContexts(contexts: [String], campaignTitle: String) -> Bool
}

/// Protocol for optional error delegate of InAppMessaging module
@objc public protocol RInAppMessagingErrorDelegate {
    /// Method will be called whenever any internal error occurs.
    /// This functionality is made for debugging purposes.
    /// Normally those errors handled by the SDK
    func inAppMessagingDidReturnError(_ error: NSError)
}

/// Class that contains the public methods for host application to call.
/// Entry point for host application to communicate with InAppMessaging.
/// Conforms to NSObject and exposed with objc tag to make it work with Obj-c projects.
@objc public class RInAppMessaging: NSObject {

    internal private(set) static var initializedModule: InAppMessagingModule?
    private(set) static var dependencyManager: DependencyManager?
    private static var inAppQueue: DispatchQueue? {
        dependencyManager?.resolve(type: DispatchQueue.self)
    }

    private override init() { super.init() }

    /// If set to `true`, displayed campaigns will have different view hierarchy
    /// allowing accessibility tools to see visible UI elements.
    /// If you use Appium for UI tests automation - set this property to true.
    /// Default value is `false`
    /// - Note: There is a possibility that changing this property will cause campaigns to display incorrectly
    @objc public static var accessibilityCompatibleDisplay = false {
        didSet {
            dependencyManager?.resolve(type: RouterType.self)?.accessibilityCompatibleDisplay = accessibilityCompatibleDisplay
        }
    }

    /// Optional error delegate for debugging purposes
    @objc public static weak var errorDelegate: RInAppMessagingErrorDelegate?

    /// Optional delegate for advanced features
    @objc public static weak var delegate: RInAppMessagingDelegate? {
        didSet {
            initializedModule?.delegate = delegate
        }
    }

    /// Function to be called by host application to start a new thread that
    /// configures Rakuten InAppMessaging SDK.
    @objc public static func configure() {
        guard initializedModule == nil else {
            return
        }

        let dependencyManager = DependencyManager()
        let mainContainer = MainContainerFactory.create(dependencyManager: dependencyManager)
        dependencyManager.appendContainer(mainContainer)
        configure(dependencyManager: dependencyManager)
    }

    static func configure(dependencyManager: DependencyManager) {
        self.dependencyManager = dependencyManager

        inAppQueue?.async(flags: .barrier) {
            guard initializedModule == nil else {
                return
            }

            guard let configurationManager = dependencyManager.resolve(type: ConfigurationManagerType.self),
                let campaignsListManager = dependencyManager.resolve(type: CampaignsListManagerType.self),
                let impressionService = dependencyManager.resolve(type: ImpressionServiceType.self),
                let eventMatcher = dependencyManager.resolve(type: EventMatcherType.self),
                let preferenceRepository = dependencyManager.resolve(type: IAMPreferenceRepository.self),
                let campaignsValidator = dependencyManager.resolve(type: CampaignsValidatorType.self),
                let readyCampaignDispatcher = dependencyManager.resolve(type: CampaignDispatcherType.self),
                let campaignTriggerAgent = dependencyManager.resolve(type: CampaignTriggerAgentType.self),
                let campaignRepository = dependencyManager.resolve(type: CampaignRepositoryType.self),
                let router = dependencyManager.resolve(type: RouterType.self) else {

                    assertionFailure("In-App Messaging SDK module initialization failure: Dependencies could not be resolved")
                    return
            }
            router.accessibilityCompatibleDisplay = accessibilityCompatibleDisplay

            initializedModule = InAppMessagingModule(configurationManager: configurationManager,
                                                     campaignsListManager: campaignsListManager,
                                                     impressionService: impressionService,
                                                     preferenceRepository: preferenceRepository,
                                                     campaignsValidator: campaignsValidator,
                                                     eventMatcher: eventMatcher,
                                                     readyCampaignDispatcher: readyCampaignDispatcher,
                                                     campaignTriggerAgent: campaignTriggerAgent,
                                                     campaignRepository: campaignRepository,
                                                     router: router)
            initializedModule?.aggregatedErrorHandler = { error in
                errorDelegate?.inAppMessagingDidReturnError(error)
            }
            initializedModule?.delegate = delegate
            initializedModule?.initialize(deinitHandler: {
                self.initializedModule = nil
                self.dependencyManager = nil
            })
        }
    }

    /// Log the event name passed in and also pass the event name to the view controller to display a matching campaign.
    /// - Parameter event: The Event object to log.
    @objc public static func logEvent(_ event: Event) {
        inAppQueue?.async(flags: .barrier) {
            initializedModule?.logEvent(event)
        }
    }

    /// Register user preference to the IAM SDK.
    /// - Parameter preference: Preferences of the user.
    @objc public static func registerPreference(_ preference: IAMPreference?) {
        inAppQueue?.async(flags: .barrier) {
            initializedModule?.registerPreference(preference)
        }
    }

    /// Close currently displayed campaign's message.
    /// This method should be called when app needs to force-close the displayed message without user action.
    /// Campaign's impressions won't be sent (i.e. the message won't be counted as displayed)
    /// - Parameter clearQueuedCampaigns: when set to true, it will clear also the list of campaigns that were
    ///                                   triggered and are queued to be displayed.
    @objc public static func closeMessage(clearQueuedCampaigns: Bool = false) {
        inAppQueue?.async(flags: .barrier) {
            initializedModule?.closeMessage(clearQueuedCampaigns: clearQueuedCampaigns)
        }
    }

    /// For testing purposes
    internal static func deinitializeModule() {
        inAppQueue?.sync {
            initializedModule = nil
        }
    }
}
