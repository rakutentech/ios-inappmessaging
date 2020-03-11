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

    private static let inAppQueue = DispatchQueue(label: "IAM.Main", attributes: .concurrent)
    private static var initializedModule: InAppMessagingModule?
    private(set) static var dependencyManager: DependencyManager?

    private override init() { super.init() }

    /// If set to `true`, displayed campaigns will have different hierarchy
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

    /// Function to be called by host application to start a new thread that
    /// configures Rakuten InAppMessaging SDK.
    @objc public static func configure() {
        guard initializedModule?.isInitialized != true else {
            return
        }

        let dependencyManager = DependencyManager()
        let mainContainer = MainContainerFactory.create(dependencyManager: dependencyManager)
        dependencyManager.appendContainer(mainContainer)
        configure(dependencyManager: dependencyManager)
    }

    static func configure(dependencyManager: DependencyManager) {
        self.dependencyManager = dependencyManager

        inAppQueue.async(flags: .barrier) {

            guard let configurationClient = dependencyManager.resolve(type: ConfigurationClient.self),
                let messageMixerClient = dependencyManager.resolve(type: MessageMixerClientType.self),
                let impressionClient = dependencyManager.resolve(type: ImpressionClientType.self),
                let eventMatcher = dependencyManager.resolve(type: EventMatcherType.self),
                let preferenceRepository = dependencyManager.resolve(type: IAMPreferenceRepository.self),
                let campaignsValidator = dependencyManager.resolve(type: CampaignsValidatorType.self),
                let readyCampaignDispatcher = dependencyManager.resolve(type: ReadyCampaignDispatcherType.self),
                let router = dependencyManager.resolve(type: RouterType.self) else {

                    assertionFailure("In-App Messaging SDK module initialization failure: Dependencies could not be resolved")
                    return
            }
            router.accessibilityCompatibleDisplay = accessibilityCompatibleDisplay

            initializedModule = InAppMessagingModule(configurationClient: configurationClient,
                                                     messageMixerClient: messageMixerClient,
                                                     impressionClient: impressionClient,
                                                     preferenceRepository: preferenceRepository,
                                                     campaignsValidator: campaignsValidator,
                                                     eventMatcher: eventMatcher,
                                                     readyCampaignDispatcher: readyCampaignDispatcher)
            initializedModule?.aggregatedErrorHandler = { error in
                errorDelegate?.inAppMessagingDidReturnError(error)
            }
            initializedModule?.initialize(restartHandler: configure) // Restart will recreate standard DependencyManager
        }
    }

    /// Log the event name passed in and also pass the event name to the view controller to display a matching campaign.
    /// - Parameter event: The Event object to log.
    @objc public static func logEvent(_ event: Event) {
        inAppQueue.async(flags: .barrier) {
            initializedModule?.logEvent(event)
        }
    }

    /// Register user preference to the IAM SDK.
    /// - Parameter preference: Preferences of the user.
    @objc public static func registerPreference(_ preference: IAMPreference?) {
        inAppQueue.async(flags: .barrier) {
            initializedModule?.registerPreference(preference)
        }
    }
}
