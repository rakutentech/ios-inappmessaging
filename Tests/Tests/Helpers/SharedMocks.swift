import Foundation
import UIKit

#if canImport(RSDKUtilsMain)
import RSDKUtilsMain // SPM version
#else
import RSDKUtils
#endif

@testable import RInAppMessaging

let TooltipViewIdentifierMock = "view.id"

class CampaignsValidatorMock: CampaignsValidatorType {
    private(set) var wasValidateCalled = false
    var campaignsToTrigger = [Campaign]()

    func validate(validatedCampaignHandler: (Campaign, Set<Event>) -> Void) {
        wasValidateCalled = true
        campaignsToTrigger.forEach {
            validatedCampaignHandler($0, [])
        }
    }
}

class CampaignRepositoryMock: CampaignRepositoryType {
    var list: [Campaign] = []
    var tooltipsList: [Campaign] {
        list.filter { $0.isTooltip }
    }
    var lastSyncInMilliseconds: Int64?
    var resourcesToLock: [LockableResource] = []
    weak var delegate: CampaignRepositoryDelegate?

    private(set) var decrementImpressionsCalls = 0
    private(set) var incrementImpressionsCalls = 0
    private(set) var wasOptOutCalled = false
    private(set) var lastSyncCampaigns = [Campaign]()
    private(set) var wasLoadCachedDataCalled = false
    private(set) var didSyncIgnoringTooltips = false

    func decrementImpressionsLeftInCampaign(id: String) -> Campaign? {
        decrementImpressionsCalls += 1
        guard let (index, campaign) = indexAndCampaign(forID: id) else {
            return nil
        }
        lastSyncCampaigns[index] = Campaign.updatedCampaign(campaign, withImpressionLeft: campaign.impressionsLeft - 1)
        return lastSyncCampaigns[index]
    }

    func incrementImpressionsLeftInCampaign(id: String) -> Campaign? {
        incrementImpressionsCalls += 1
        guard let (index, campaign) = indexAndCampaign(forID: id) else {
            return nil
        }
        lastSyncCampaigns[index] = Campaign.updatedCampaign(campaign, withImpressionLeft: campaign.impressionsLeft + 1)
        return lastSyncCampaigns[index]
    }

    func optOutCampaign(_ campaign: Campaign) -> Campaign? {
        wasOptOutCalled = true
        return Campaign.updatedCampaign(campaign, asOptedOut: true)
    }

    func syncWith(list: [Campaign], timestampMilliseconds: Int64, ignoreTooltips: Bool) {
        lastSyncCampaigns = list
        didSyncIgnoringTooltips = ignoreTooltips
    }

    func loadCachedData() {
        wasLoadCachedDataCalled = true
    }

    func resetFlags() {
        decrementImpressionsCalls = 0
        incrementImpressionsCalls = 0
        wasOptOutCalled = false
        lastSyncCampaigns = [Campaign]()
        wasLoadCachedDataCalled = false
    }

    private func indexAndCampaign(forID id: String) -> (Int, Campaign)? {
        for (index, campaign) in lastSyncCampaigns.enumerated() where campaign.id == id {
            return (index, campaign)
        }
        return nil
    }
}

class CampaignDispatcherMock: CampaignDispatcherType {
    weak var delegate: CampaignDispatcherDelegate?
    var wasDispatchCalled = false
    var addedCampaignIDs = [String]()
    var wasResetQueueCalled = false

    func addToQueue(campaignID: String) {
        addedCampaignIDs.append(campaignID)
    }
    func dispatchAllIfNeeded() {
        wasDispatchCalled = true
    }
    func resetQueue() {
        wasResetQueueCalled = true
    }
}

class EventMatcherMock: EventMatcherType {
    private(set) var loggedEvents = [Event]()
    var simulateMatchingSuccess = true
    var simulateMatcherError: EventMatcherError?
    var resourcesToLock: [LockableResource] = []
    var wasClearNonPersistentEventsCalled = false

    func matchAndStore(event: Event) {
        loggedEvents.append(event)
    }

    func matchedEvents(for campaign: Campaign) -> [Event] { return [] }

    func containsAllMatchedEvents(for campaign: Campaign) -> Bool {
        simulateMatchingSuccess
    }

    func removeSetOfMatchedEvents(_ eventsToRemove: Set<Event>, for campaign: Campaign) throws {
        if let error = simulateMatcherError {
            throw error
        }
        if !simulateMatchingSuccess {
            throw EventMatcherError.couldntFindRequestedSetOfEvents
        }
    }

    func clearNonPersistentEvents() {
        wasClearNonPersistentEventsCalled = true
    }
}

class MessageMixerServiceMock: MessageMixerServiceType {
    var wasPingCalled = false
    var mockedResponse: PingResponse?
    var mockedError = MessageMixerServiceError.invalidConfiguration
    var pingCallCount = 0

    private let suspendSemaphore = DispatchGroup()
    private var shouldSuspend = false

    func ping() -> Result<PingResponse, MessageMixerServiceError> {
        wasPingCalled = true
        pingCallCount += 1

        if shouldSuspend {
            guard Thread.current != .main else {
                fatalError("Ping suspension shoudn't be used on the main thread")
            }
            shouldSuspend = false
            suspendSemaphore.wait()
        }

        if let mockedResponse = mockedResponse {
            return .success(mockedResponse)
        }
        return .failure(mockedError)
    }

    /// call returned closure to send resume signal
    func suspendNextPingAndWaitForSignal() -> (() -> Void) {
        guard !shouldSuspend else {
            fatalError("MessageMixerServiceMock: Suspend race condition")
        }
        shouldSuspend = true
        suspendSemaphore.enter()
        return { [weak self] in
            self?.suspendSemaphore.leave()
        }
    }
}

class DisplayPermissionServiceMock: DisplayPermissionServiceType {
    var shouldGrantPermission = true
    var shouldPerformPing = false
    weak var errorDelegate: ErrorDelegate?

    func checkPermission(forCampaign campaign: CampaignData) -> DisplayPermissionResponse {
        DisplayPermissionResponse(display: shouldGrantPermission,
                                  performPing: shouldPerformPing)
    }
}

class ConfigurationManagerMock: ConfigurationManagerType {
    weak var errorDelegate: ErrorDelegate?
    var rolloutPercentage = 100
    var fetchCalledClosure = {}

    private let retryQueue = DispatchQueue(label: "ConfigurationManagerMock.retryQueue")
    private let retrySemaphore = DispatchGroup()
    private var shouldSimulateRetry = false
    private let configRepository: ConfigurationRepositoryType?

    init(configurationRepository: ConfigurationRepositoryType? = nil) {
        self.configRepository = configurationRepository
    }

    func fetchAndSaveConfigData(completion: @escaping (ConfigEndpointData) -> Void) {
        fetchCalledClosure()

        guard shouldSimulateRetry else {
            completion(ConfigEndpointData(rolloutPercentage: rolloutPercentage, endpoints: .empty))
            return
        }
        shouldSimulateRetry = false
        retrySemaphore.enter()
        retryQueue.async { [weak self] in
            self?.retrySemaphore.wait()
            self?.fetchAndSaveConfigData(completion: completion)
        }
    }

    func save(moduleConfig config: InAppMessagingModuleConfiguration) {
        configRepository?.saveIAMModuleConfiguration(config)
    }

    /// call returned closure to send resume signal
    func prepareRetryDelayAndWaitForSignal() -> (() -> Void) {
        shouldSimulateRetry = true
        return { [weak self] in
            self?.retrySemaphore.leave()
        }
    }
}

class ReachabilityMock: ReachabilityType {
    var connectionStub = Reachability.Connection.wifi {
        didSet {
            observers.forEach { $0.value?.reachabilityChanged(self) }
        }
    }
    var connection: Reachability.Connection {
        connectionStub
    }

    var observers = [WeakWrapper<ReachabilityObserver>]()

    func addObserver(_ observer: ReachabilityObserver) {
        observers.append(WeakWrapper(value: observer))
    }
    func removeObserver(_ observer: ReachabilityObserver) {
        observers.removeAll { $0.value === observer }
    }
}

class ConfigurationServiceMock: ConfigurationServiceType {
    var getConfigDataCallCount = 0
    var simulateRequestFailure = false
    var mockedError = ConfigurationServiceError.requestError(.unknown)
    var rolloutPercentage = 100

    func getConfigData() -> Result<ConfigEndpointData, ConfigurationServiceError> {
        getConfigDataCallCount += 1

        guard !simulateRequestFailure else {
            return .failure(mockedError)
        }

        return .success(ConfigEndpointData(rolloutPercentage: rolloutPercentage, endpoints: .empty))
    }
}

class CampaignTriggerAgentMock: CampaignTriggerAgentType {
    private(set) var wasValidateAndTriggerCampaignsCalled = false

    func validateAndTriggerCampaigns() {
        wasValidateAndTriggerCampaignsCalled = true
    }
}

class ImpressionServiceMock: ImpressionServiceType {
    weak var errorDelegate: ErrorDelegate?
    var sentImpressions: (list: [ImpressionType], campaignID: String)?

    func pingImpression(impressions: [Impression], campaignData: CampaignData) {
        sentImpressions = (impressions.map({ $0.type }), campaignData.campaignId)
    }
}

class BundleInfoMock: BundleInfo {
    static var applicationIdMock: String? = "app.id"
    static var appVersionMock: String? = "1.2.3"
    static var inAppSdkVersionMock: String? = "0.0.5"
    static var customFontMock: String? = "blank-Bold"

    static func reset() {
        applicationIdMock = "app.id"
        appVersionMock = "1.2.3"
        inAppSdkVersionMock = "0.0.5"
        customFontMock = "blank-Bold"
    }

    override class var applicationId: String? {
        applicationIdMock
    }

    override class var appVersion: String? {
        appVersionMock
    }

    override class var inAppSdkVersion: String? {
        inAppSdkVersionMock
    }

    override class var customFontNameTitle: String? {
        customFontMock
    }

    override class var customFontNameText: String? {
        customFontMock
    }

    override class var customFontNameButton: String? {
        customFontMock
    }
}

class CampaignsListManagerMock: CampaignsListManagerType {
    weak var errorDelegate: ErrorDelegate?
    private(set) var wasRefreshListCalled = false

    func refreshList() {
        wasRefreshListCalled = true
    }
}

class RouterMock: RouterType {
    var accessibilityCompatibleDisplay = false
    var lastDisplayedCampaign: Campaign?
    var displayedTooltips = [Campaign]()
    var displayedCampaignsCount = 0
    var wasDiscardCampaignCalled = false
    var wasDisplayCampaignCalled = false
    var lastIdentifierOfDiscardedTooltip: String?
    var displayTime = TimeInterval(0.1)
    weak var errorDelegate: ErrorDelegate?

    private var tooltipCompletion: ((_ cancelled: Bool) -> Void)?
    private var tooltipBecameVisibleHandler: ((TooltipView) -> Void)?

    private let displayQueue = DispatchQueue(label: "RouterMock.displayQueue")

    func displayCampaign(_ campaign: Campaign,
                         associatedImageData: Data?,
                         confirmation: @escaping @autoclosure () -> Bool,
                         completion: @escaping (_ cancelled: Bool) -> Void) {

        wasDisplayCampaignCalled = true
        guard confirmation() else {
            completion(true)
            return
        }
        let delayUSeconds = Int(displayTime * Double(USEC_PER_SEC))
        displayQueue.asyncAfter(deadline: .now() + .microseconds(delayUSeconds)) { [weak self] in
            guard let self = self else {
                return
            }
            self.lastDisplayedCampaign = campaign
            self.displayedCampaignsCount += 1
            completion(false)
        }
    }

    // swiftlint:disable:next function_parameter_count
    func displayTooltip(_ tooltip: Campaign,
                        targetView: UIView,
                        identifier: String,
                        imageBlob: Data,
                        becameVisibleHandler: @escaping (TooltipView) -> Void,
                        confirmation: @autoclosure @escaping () -> Bool,
                        completion: @escaping (Bool) -> Void) {
        tooltipBecameVisibleHandler = becameVisibleHandler
        tooltipCompletion = completion

        let delay = DispatchTimeInterval.milliseconds(100)
        displayQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self,
                  confirmation() else {
                return
            }
            self.displayedTooltips.append(tooltip)
        }
    }

    func displaySwiftUITooltip(_ tooltip: Campaign,
                               tooltipView: TooltipView,
                               identifier: String,
                               imageBlob: Data,
                               confirmation: @autoclosure @escaping () -> Bool,
                               completion: @escaping (Bool) -> Void) {
    }

    func discardDisplayedCampaign() {
        wasDiscardCampaignCalled = true
    }

    func completeDisplayingTooltip(cancelled: Bool) {
        tooltipCompletion?(cancelled)
        tooltipCompletion = nil
        tooltipBecameVisibleHandler = nil
    }

    func callTooltipBecameVisibleHandler(tooltipView: TooltipView) {
        tooltipBecameVisibleHandler?(tooltipView)
    }

    func discardDisplayedTooltip(with uiElementIdentifier: String) {
        lastIdentifierOfDiscardedTooltip = uiElementIdentifier
    }

    func isDisplayingTooltip(with uiElementIdentifier: String) -> Bool {
        false
    }
}

class UserDataCacheMock: UserDataCacheable {
    var userDataMock: UserDataCacheContainer?
    var cachedCampaignData: [Campaign]?
    var cachedDisplayPermissionData: (DisplayPermissionResponse, String)?
    var cachedData = [[UserIdentifier]: UserDataCacheContainer]()

    func getUserData(identifiers: [UserIdentifier]) -> UserDataCacheContainer? {
        userDataMock ?? cachedData[identifiers]
    }

    func cacheCampaignData(_ data: [Campaign], userIdentifiers: [UserIdentifier]) {
        cachedCampaignData = data
        cachedData[userIdentifiers] = UserDataCacheContainer(campaignData: data)
    }

    func cacheDisplayPermissionData(_ data: DisplayPermissionResponse, campaignID: String, userIdentifiers: [UserIdentifier]) {
        cachedDisplayPermissionData = (data, campaignID)
        cachedData[userIdentifiers] = UserDataCacheContainer(displayPermissionData: [campaignID: data])
    }

    func userHash(from identifiers: [UserIdentifier]) -> String {
        identifiers.map({ $0.identifier }).joined()
    }

    func deleteUserData(identifiers: [UserIdentifier]) { }
}

class UserInfoProviderMock: UserInfoProvider {
    var accessToken: String?
    var userID: String?
    var idTrackingIdentifier: String?

    func getAccessToken() -> String? { accessToken }

    func getUserID() -> String? { userID }

    func getIDTrackingIdentifier() -> String? { idTrackingIdentifier }

    func clear() {
        accessToken = nil
        userID = nil
        idTrackingIdentifier = nil
    }
}

class AccountRepositorySpy: AccountRepositoryType {
    let realAccountRepository = AccountRepository(userDataCache: UserDataCacheMock())
    private(set) var wasUpdateUserInfoCalled = false

    var userInfoProvider: UserInfoProvider? {
        realAccountRepository.userInfoProvider
    }

    @discardableResult
    func updateUserInfo() -> Bool {
        wasUpdateUserInfoCalled = true
        return realAccountRepository.updateUserInfo()
    }

    func setPreference(_ preference: UserInfoProvider) {
        realAccountRepository.setPreference(preference)
    }

    func registerAccountUpdateObserver(_ observer: UserChangeObserver) {
        realAccountRepository.registerAccountUpdateObserver(observer)
    }

    func getUserIdentifiers() -> [UserIdentifier] {
        realAccountRepository.getUserIdentifiers()
    }
}

final class RandomizerMock: RandomizerType {
    var returnedValue: UInt = 0
    var dice: UInt {
        returnedValue
    }
}

final class LockableTestObject: Lockable {
    var resourcesToLock: [LockableResource] {
        [resource]
    }
    let resource = LockableObject([Int]())

    func append(_ number: Int) {
        var resource = self.resource.get()
        resource.append(number)
        self.resource.set(value: resource)
    }

    func lockResources() {
        resourcesToLock.forEach { $0.lock() }
    }

    func unlockResources() {
        resourcesToLock.forEach { $0.unlock() }
    }
}

final class ErrorDelegateMock: ErrorDelegate {
    private(set) var wasErrorReceived = false
    private(set) var receivedError: NSError?

    func didReceive(error: NSError) {
        wasErrorReceived = true
        receivedError = error
    }
}

final class UNUserNotificationCenterMock: RemoteNotificationRequestable {
    private(set) var requestAuthorizationCallState: (didCall: Bool, options: UNAuthorizationOptions?) = (false, nil)
    private(set) var didCallRegisterForRemoteNotifications = false
    var authorizationRequestError: Error?
    var authorizationGranted = true
    var authorizationStatus = UNAuthorizationStatus.notDetermined

    func requestAuthorization(options: UNAuthorizationOptions = [],
                              completionHandler: @escaping (Bool, Error?) -> Void) {
        requestAuthorizationCallState = (didCall: true, options: options)
        completionHandler(authorizationGranted, authorizationRequestError)
    }

    func registerForRemoteNotifications() {
        didCallRegisterForRemoteNotifications = true
    }

    func getAuthorizationStatus(completionHandler: @escaping (UNAuthorizationStatus) -> Void) {
        completionHandler(authorizationStatus)
    }
}

final class TooltipDispatcherMock: TooltipDispatcherType {
    private(set) var needsDisplayTooltips = [Campaign]()
    weak var delegate: TooltipDispatcherDelegate?

    func setNeedsDisplay(tooltip: Campaign) {
        needsDisplayTooltips.append(tooltip)
    }

    func registerSwiftUITooltip(identifier: String, uiView: TooltipView) {
    }
}

final class ViewListenerMock: ViewListenerType {

    private(set) var wasIterateOverDisplayedViewsCalled = false
    private(set) var observers = [WeakWrapper<ViewListenerObserver>]()
    var displayedViews = [UIView]()

    func addObserver(_ observer: ViewListenerObserver) {
        observers.append(WeakWrapper(value: observer))
    }

    func startListening() { }

    func stopListening() { }

    func iterateOverDisplayedViews(_ handler: @escaping (UIView, String, inout Bool) -> Void) {
        wasIterateOverDisplayedViewsCalled = true

        DispatchQueue.main.async {
            var stop = false
            for existingView in self.displayedViews {
                guard !stop else {
                    return
                }
                guard let identifier = existingView.accessibilityIdentifier, !identifier.isEmpty else {
                    continue
                }
                handler(existingView, identifier, &stop)
            }
        }
    }
}

final class TooltipPresenterMock: TooltipPresenterType {
    var tooltip: Campaign?
    var onDismiss: ((Bool) -> Void)?
    var impressions: [Impression] = []
    var impressionService: ImpressionServiceType = ImpressionServiceMock()

    private(set) var wasDidTapImageCalled = false
    private(set) var wasDidTapExitButtonCalled = false
    private(set) var wasDismissCalled = false
    private(set) var startedAutoDisappearing = false

    func set(view: TooltipView, dataModel data: Campaign, image: UIImage) {

    }

    func didTapExitButton() {
        wasDidTapExitButtonCalled = true
    }

    func didTapImage() {
        wasDidTapImageCalled = true
    }

    func dismiss() {
        wasDismissCalled = true
    }

    func startAutoDisappearIfNeeded() {
        startedAutoDisappearing = true
    }

    func didRemoveFromSuperview() {
    }
}

final class TooltipViewMock: TooltipView {
    private(set) var startedAutoDisappearing = false
    private(set) var setupModel: TooltipViewModel?
    private(set) var didCallRemoveFromSuperview = false

    convenience init() {
        self.init(presenter: TooltipPresenterMock())
    }

    override func setup(model: TooltipViewModel) {
        setupModel = model
    }

    override func removeFromSuperview() {
        didCallRemoveFromSuperview = true
    }
}

final class InAppMessagingModuleMock: InAppMessagingModule {
    private(set) var loggedEvent: Event?

    init() {
        super.init(configurationManager: ConfigurationManagerMock(),
                   campaignsListManager: CampaignsListManagerMock(),
                   impressionService: ImpressionServiceMock(),
                   accountRepository: AccountRepository(userDataCache: UserDataCacheMock()),
                   eventMatcher: EventMatcherMock(),
                   readyCampaignDispatcher: CampaignDispatcherMock(),
                   campaignTriggerAgent: CampaignTriggerAgentMock(),
                   campaignRepository: CampaignRepositoryMock(),
                   router: RouterMock(),
                   randomizer: RandomizerMock(),
                   displayPermissionService: DisplayPermissionServiceMock(),
                   tooltipDispatcher: TooltipDispatcherMock())
    }

    override func initialize(completion: @escaping (Bool) -> Void) {
        completion(false)
    }

    override func logEvent(_ event: Event) {
        loggedEvent = event
    }
}

extension EndpointURL {
    static var empty: Self {
        let emptyURL = URL(string: "about:blank")!
        return EndpointURL(ping: emptyURL,
                           displayPermission: emptyURL,
                           impression: emptyURL)
    }

    static var invalid: Self {
        EndpointURL(ping: nil,
                    displayPermission: nil,
                    impression: nil)
    }
}
