import Foundation
#if canImport(RSDKUtilsMain)
import RSDKUtilsMain // SPM version
#else
import RSDKUtils
#endif

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
@objc public final class RInAppMessaging: NSObject {

    internal private(set) static var initializedModule: InAppMessagingModule?
    private(set) static var dependencyManager: TypedDependencyManager?
    internal static let inAppQueue = DispatchQueue(label: "IAM.Main", qos: .utility, attributes: [])

    private override init() { super.init() }

    /// If set to `true`, displayed campaigns will have different view hierarchy
    /// allowing accessibility tools to see visible UI elements.
    /// If you use Appium for UI tests automation - set this property to true.
    /// Default value is `false`
    /// - Note: There is a possibility that changing this property will cause campaigns to display incorrectly
    @objc public static var accessibilityCompatibleDisplay = false {
        didSet {
            inAppQueue.async {
                dependencyManager?.resolve(type: RouterType.self)?.accessibilityCompatibleDisplay = accessibilityCompatibleDisplay
            }
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

        let dependencyManager = TypedDependencyManager()
        let mainContainer = MainContainerFactory.create(dependencyManager: dependencyManager)
        dependencyManager.appendContainer(mainContainer)
        configure(dependencyManager: dependencyManager)
    }

    static func configure(dependencyManager: TypedDependencyManager) {
        self.dependencyManager = dependencyManager

        inAppQueue.async {
            guard initializedModule == nil else {
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
                let _ = dependencyManager.resolve(type: TooltipManagerType.self) else {

                    assertionFailure("In-App Messaging SDK module initialization failure: Dependencies could not be resolved")
                    return
            }
            router.accessibilityCompatibleDisplay = accessibilityCompatibleDisplay

            initializedModule = InAppMessagingModule(configurationManager: configurationManager,
                                                     campaignsListManager: campaignsListManager,
                                                     impressionService: impressionService,
                                                     accountRepository: accountRepository,
                                                     eventMatcher: eventMatcher,
                                                     readyCampaignDispatcher: readyCampaignDispatcher,
                                                     campaignTriggerAgent: campaignTriggerAgent,
                                                     campaignRepository: campaignRepository,
                                                     router: router,
                                                     randomizer: randomizer,
                                                     displayPermissionService: displayPermissionService)
            initializedModule?.aggregatedErrorHandler = { error in
                errorDelegate?.inAppMessagingDidReturnError(error)
            }
            initializedModule?.delegate = delegate
            initializedModule?.initialize { shouldDeinit in
                if shouldDeinit {
                    self.initializedModule = nil
                    self.dependencyManager = nil
                    viewListener.stopListening()
                } else {
                    viewListener.startListening()
                }
            }
        }
    }

    /// Log the event name passed in and also pass the event name to the view controller to display a matching campaign.
    /// - Parameter event: The Event object to log.
    @objc public static func logEvent(_ event: Event) {
        inAppQueue.async {
            notifyIfModuleNotInitialized()
            initializedModule?.logEvent(event)
        }
    }

    /// Register user preference object to the IAM SDK.
    ///
    /// Registered object should be updated to reflect current user session state.
    /// Should only be called once unless new `UserInfoProvider` object has been created.
    /// - Note: This method creates a strong reference to provided object.
    /// - Parameter provider: object that will always contain up-to-date user information.
    @objc public static func registerPreference(_ provider: UserInfoProvider) {
        inAppQueue.async {
            initializedModule?.registerPreference(provider)
        }
    }

    /// Close currently displayed campaign's message.
    ///
    /// This method should be called when app needs to force-close the displayed message without user action.
    /// Campaign's impressions won't be sent (i.e. the message won't be counted as displayed)
    /// - Parameter clearQueuedCampaigns: when set to true, it will clear also the list of campaigns that were
    ///                                   triggered and are queued to be displayed.
    @objc public static func closeMessage(clearQueuedCampaigns: Bool = false) {
        inAppQueue.async {
            notifyIfModuleNotInitialized()
            initializedModule?.closeMessage(clearQueuedCampaigns: clearQueuedCampaigns)
        }
    }

    private static func notifyIfModuleNotInitialized() {
        guard initializedModule == nil else {
            return
        }

        let description = "⚠️ API method called before calling `configure()`"
        let error = NSError(domain: "InAppMessaging.\(type(of: self))",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "InAppMessaging: " + description])
        Logger.debug(description)
        errorDelegate?.inAppMessagingDidReturnError(error)
    }

    // MARK: - Unit tests
    internal static func deinitializeModule() {
        inAppQueue.sync {
            dependencyManager?.resolve(type: ViewListenerType.self)?.stopListening()
            initializedModule = nil
            dependencyManager = nil
        }
    }

    internal static func setModule(_ iamModule: InAppMessagingModule?) {
        initializedModule = iamModule
    }
}
