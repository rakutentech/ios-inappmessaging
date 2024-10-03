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

    private(set) static var dependencyManager: TypedDependencyManager?
    internal static let inAppQueue = DispatchQueue(label: "IAM.Main", qos: .utility, attributes: [])
    internal static var swiftUIEventHandler: SwiftUIViewEventHandlerType? {
        dependencyManager?.resolve(type: SwiftUIViewEventHandlerType.self)
    }
    
    internal static var bundleInfo = BundleInfo.self
    
    internal static var isInitialized: Bool {
        interactor.iamModule != nil
    }
    internal static var isUserRegistered: Bool = false
    internal static let interactor = InAppMessagingInteractor()

    /// Returns `true` when RMC module is integrated in the host app
    internal static var isRMCEnvironment: Bool {
        bundleInfo.rmcBundle != nil
    }

    private override init() { super.init() }

    /// If set to `true`, displayed campaigns will have different view hierarchy
    /// allowing accessibility tools to see visible UI elements.
    /// If you use Appium for UI tests automation - set this property to true.
    /// Default value is `false`
    /// - Note: There is a possibility that changing this property will cause campaigns to display incorrectly
    @objc public static var accessibilityCompatibleDisplay: Bool {
        get {
            interactor.accessibilityCompatibleDisplay
        }
        set {
            interactor.accessibilityCompatibleDisplay = newValue
        }
    }

    /// An optional callback called only for campaigns with defined context just before displaying its message.
    /// Return `false` to prevent the message from displaying.
    @objc public static var onVerifyContext: ((_ contexts: [String], _ campaignTitle: String) -> Bool)? {
        get {
            interactor.onVerifyContext
        }
        set {
            interactor.onVerifyContext = newValue
        }
    }

    /// A closure called whenever any internal error occurs.
    /// This functionality is made for debugging purposes to provide more information for developers.
    @objc public static var errorCallback: ((NSError) -> Void)? {
        get {
            interactor.errorCallback
        }
        set {
            interactor.errorCallback = newValue
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
        IAMLogger.debugLog("configure")
        guard verifyRMCEnvironment(subscriptionID: subscriptionID), !isInitialized else {
            let description = "⚠️ SDK configure request rejected. Initialization status: \(isInitialized)"
            let error = NSError.iamError(description: description)
            IAMLogger.debug(description)
            errorCallback?(error)
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

    internal static func configure(dependencyManager: TypedDependencyManager,
                                   moduleConfig: InAppMessagingModuleConfiguration,
                                   completion: ((Bool) -> Void)? = nil) {
        self.dependencyManager = dependencyManager

        inAppQueue.async {
            self.interactor.configure(dependencyManager: dependencyManager, moduleConfig: moduleConfig, completion: { shouldDeinit in
                defer {
                    completion?(shouldDeinit)
                }
                guard shouldDeinit else {
                    return
                }
                self.dependencyManager = nil
            })
        }
    }

    /// Log the event name passed in and also pass the event name to the view controller to display a matching campaign.
    /// - Parameter event: The Event object to log.
    @objc public static func logEvent(_ event: Event) {
        IAMLogger.debugLog("logEvent: \(event)")
        if !isUserRegistered {
            IAMLogger.debug("⚠️ Warning: RegisterPreference should be called before logging any Events.")
        }
        inAppQueue.async {
            interactor.logEvent(event)
        }
    }

    /// Register user preference object to the IAM SDK.
    ///
    /// Registered object should be updated to reflect current user session state.
    /// Should only be called once unless new `UserInfoProvider` object has been created.
    /// - Note: This method creates a strong reference to provided object.
    /// - Parameter provider: object that will always contain up-to-date user information.
    @objc public static func registerPreference(_ provider: UserInfoProvider) {
        IAMLogger.debugLog("registerPreference: \(provider)")
        isUserRegistered = true
        inAppQueue.async {
            interactor.userPerference = provider
        }
    }

    /// Close currently displayed campaign's message.
    ///
    /// This method should be called when app needs to force-close the displayed message without user action.
    /// Campaign's impressions won't be sent (i.e. the message won't be counted as displayed)
    /// - Parameter clearQueuedCampaigns: when set to true, it will clear also the list of campaigns that were
    ///                                   triggered and are queued to be displayed.
    @objc public static func closeMessage(clearQueuedCampaigns: Bool = false) {
        IAMLogger.debugLog("closeMessage")
        inAppQueue.async {
            interactor.closeMessage(clearQueuedCampaigns: clearQueuedCampaigns)
        }
    }

    /// Close currently displayed tooltip that's bound to a UI element with given identifier.
    ///
    /// This method should be called when app needs to force-close displayed tooltip without user action.
    /// Tooltip's impressions won't be sent (i.e. the message won't be counted as displayed)
    /// - Parameter uiElementIdentifier: accessibilityIdentifier of UI element that displayed tooltip is attached to.
    ///                                  (a.k.a. `UIElement` parameter in tooltip JSON payload)
    @objc public static func closeTooltip(with uiElementIdentifier: String) {
        IAMLogger.debugLog("closeTooltip : \(uiElementIdentifier)")
        inAppQueue.async {
            interactor.closeTooltip(with: uiElementIdentifier)
        }
    }

    // visible for unit tests
    internal static func tryGettingValidConfigURL(_ config: InAppMessagingModuleConfiguration) -> URL {
        
        guard let url = config.configURLString , let configURL = URL(string: url) else {
            let description = "⚠️ Invalid Configuration URL: \(config.configURLString ?? "<empty>")"
            let error = NSError.iamError(description: description)
            IAMLogger.debug(description)
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
            setModule(nil)
            dependencyManager = nil
            interactor.userPerference = nil
        }
    }

    internal static func setModule(_ iamModule: InAppMessagingModule?) {
        interactor.iamModule = iamModule
    }
}
