import Foundation
import struct UserNotifications.UNAuthorizationOptions

#if SWIFT_PACKAGE
import RSDKUtilsMain
#else
import RSDKUtils
#endif

/// Class that contains the public methods for host application to call.
/// Entry point for host application to communicate with InAppMessaging.
/// Conforms to NSObject and exposed with objc tag to make it work with Obj-c projects.
@objc public final class RInAppMessaging: NSObject {

    internal private(set) static var initializedModule: InAppMessagingModule?
    private(set) static var dependencyManager: TypedDependencyManager?
    internal static let inAppQueue = DispatchQueue(label: "IAM.Main", qos: .utility, attributes: [])
    internal static var swiftUIEventHandler: SwiftUIViewEventHandlerType? {
        dependencyManager?.resolve(type: SwiftUIViewEventHandlerType.self)
    }

    /// Returns `true` when RMC module is integrated in the host app
    internal static var isRMCEnvironment: Bool {
        Bundle.rmcResources != nil
    }

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

    /// An optional callback called only for campaigns with defined context just before displaying its message.
    /// Return `false` to prevent the message from displaying.
    @objc public static var onVerifyContext: ((_ contexts: [String], _ campaignTitle: String) -> Bool)? {
        didSet {
            initializedModule?.onVerifyContext = onVerifyContext
        }
    }

    /// A closure called whenever any internal error occurs.
    /// This functionality is made for debugging purposes to provide more information for developers.
    @objc public static var errorCallback: ((NSError) -> Void)? {
        didSet {
            initializedModule?.aggregatedErrorHandler = errorCallback
        }
    }

    /// User Notification Authorization Options used in Push Primer feature.
    /// Value of this property will be used to register for remote notifications.
    /// The default value is `[.sound, .alert, .badge]`
    @objc public static var pushPrimerAuthorizationOptions: UNAuthorizationOptions = [.sound, .alert, .badge]

    /// Function to be called by host application to start a new thread that
    /// configures Rakuten InAppMessaging SDK.
    /// - Parameters:
    ///     - subscriptionKey: your app's subscription key. (This setting will override the `InAppMessagingAppSubscriptionID` value in Info.plist)
    ///     - configurationURL: a configuration URL. (This setting will override the `InAppMessagingConfigurationURL` value in Info.plist)
    ///     - enableTooltipFeature: set to `true` to enable Tooltip campaigns. This feature is currently in beta phase. Default value: `false`.
    @objc public static func configure(subscriptionID: String? = nil,
                                       configurationURL: String? = nil,
                                       enableTooltipFeature: Bool = false) {

        guard verifyRMCEnvironment(subscriptionID: subscriptionID), initializedModule == nil else {
            return
        }

        let config = InAppMessagingModuleConfiguration(
            configURLString: configurationURL ?? BundleInfo.inAppConfigurationURL,
            subscriptionID: sanitizeSubscriptionID(subscriptionID) ?? BundleInfo.inAppSubscriptionId,
            isTooltipFeatureEnabled: enableTooltipFeature)

        let dependencyManager = TypedDependencyManager()
        let validConfigURL = tryGettingValidConfigURL(config)
        let mainContainer = MainContainerFactory.create(dependencyManager: dependencyManager, configURL: validConfigURL)
        dependencyManager.appendContainer(mainContainer)
        configure(dependencyManager: dependencyManager, moduleConfig: config)
    }

    internal static func configure(dependencyManager: TypedDependencyManager, moduleConfig: InAppMessagingModuleConfiguration) {
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
                  let _ = dependencyManager.resolve(type: TooltipEventSenderType.self),
                  let tooltipDispatcher = dependencyManager.resolve(type: TooltipDispatcherType.self) else {

                assertionFailure("In-App Messaging SDK module initialization failure: Dependencies could not be resolved")
                return
            }
            router.accessibilityCompatibleDisplay = accessibilityCompatibleDisplay
            configurationManager.save(moduleConfig: moduleConfig)

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
                                                     displayPermissionService: displayPermissionService,
                                                     tooltipDispatcher: tooltipDispatcher)
            initializedModule?.aggregatedErrorHandler = errorCallback
            initializedModule?.onVerifyContext = onVerifyContext
            initializedModule?.initialize { shouldDeinit in
                if shouldDeinit {
                    self.initializedModule = nil
                    self.dependencyManager = nil
                    viewListener.stopListening()
                } else if moduleConfig.isTooltipFeatureEnabled {
                    viewListener.startListening()
                }
            }
        }
    }

    /// Log the event name passed in and also pass the event name to the view controller to display a matching campaign.
    /// - Parameter event: The Event object to log.
    /// - Warning: ⚠️ Calling this method prior to `configure()` has no effect.
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
    /// - Warning: ⚠️ Calling this method prior to `configure()` has no effect.
    /// - Parameter provider: object that will always contain up-to-date user information.
    @objc public static func registerPreference(_ provider: UserInfoProvider) {
        inAppQueue.async {
            notifyIfModuleNotInitialized()
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

    /// Close currently displayed tooltip that's bound to a UI element with given identifier.
    ///
    /// This method should be called when app needs to force-close displayed tooltip without user action.
    /// Tooltip's impressions won't be sent (i.e. the message won't be counted as displayed)
    /// - Parameter uiElementIdentifier: accessibilityIdentifier of UI element that displayed tooltip is attached to.
    ///                                  (a.k.a. `UIElement` parameter in tooltip JSON payload)
    @objc public static func closeTooltip(with uiElementIdentifier: String) {
        inAppQueue.async {
            notifyIfModuleNotInitialized()
            initializedModule?.closeTooltip(with: uiElementIdentifier)
        }
    }

    internal static func notifyIfModuleNotInitialized() {
        guard initializedModule == nil else {
            return
        }

        let description = "⚠️ API method called before calling `configure()`"
        let error = NSError.iamError(description: description)
        Logger.debug(description)
        errorCallback?(error)
    }

    // visible for unit tests
    internal static func tryGettingValidConfigURL(_ config: InAppMessagingModuleConfiguration) -> URL {
        
        guard let url = config.configURLString , let configURL = URL(string: url) else {
            let description = "⚠️ Invalid Configuration URL: \(config.configURLString ?? "<empty>")"
            let error = NSError.iamError(description: description)
            Logger.debug(description)
            errorCallback?(error)
            assertionFailure(description)
            return URL(string: "invalid")!
        }

        return configURL
    }

    /// Checks the existence of RMC module and verifies the `configure()` caller.
    /// - Parameter subscriptionID: a subscriptionID value from `configure()` call to check for '-rmc' suffix
    /// - Returns: `false` if RMC module is integrated and the method wasn't called from the RMC module.
    internal static func verifyRMCEnvironment(subscriptionID: String?) -> Bool {
        guard isRMCEnvironment else {
            return true
        }

        return subscriptionID?.hasSuffix(Constants.RMC.subscriptionIDSuffix) == true
    }

    /// Removes '-rmc' suffix from subscriptionId if it's present.
    internal static func sanitizeSubscriptionID(_ subscriptionID: String?) -> String? {
        guard let subscriptionID = subscriptionID else {
            return nil
        }

        guard subscriptionID.hasSuffix(Constants.RMC.subscriptionIDSuffix) else {
            return subscriptionID
        }

        return String(subscriptionID.prefix(subscriptionID.count - Constants.RMC.subscriptionIDSuffix.count))
    }

    // MARK: - Unit tests helpers
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
