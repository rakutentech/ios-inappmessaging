import Foundation
#if canImport(RSDKUtilsMain)
import RSDKUtilsMain // SPM version
#else
import RSDKUtils
#endif
@testable import RInAppMessaging

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
    var lastSyncInMilliseconds: Int64?
    var resourcesToLock: [LockableResource] = []

    private(set) var decrementImpressionsCalls = 0
    private(set) var incrementImpressionsCalls = 0
    private(set) var wasOptOutCalled = false
    private(set) var lastSyncCampaigns = [Campaign]()
    private(set) var wasLoadCachedDataCalled = false
    private(set) var loadCachedDataParameters: (Bool)?
    private(set) var wasClearLastUserDataCalled = false

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

    func syncWith(list: [Campaign], timestampMilliseconds: Int64) {
        lastSyncCampaigns = list
    }

    func loadCachedData(syncWithLastUserData: Bool) {
        wasLoadCachedDataCalled = true
        loadCachedDataParameters = (syncWithLastUserData)
    }

    func resetFlags() {
        decrementImpressionsCalls = 0
        incrementImpressionsCalls = 0
        wasOptOutCalled = false
        lastSyncCampaigns = [Campaign]()
        wasLoadCachedDataCalled = false
        loadCachedDataParameters = nil
        wasClearLastUserDataCalled = false
    }

    func clearLastUserData() {
        wasClearLastUserDataCalled = true
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
        return simulateMatchingSuccess
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
    var delay: TimeInterval = 0

    func ping() -> Result<PingResponse, MessageMixerServiceError> {
        self.wasPingCalled = true
        if delay > 0 {
            guard Thread.current != .main else {
                fatalError("Delay function shoudn't be used on the main thread")
            }
            usleep(UInt32(UInt64(delay) * USEC_PER_SEC))
        }

        if let mockedResponse = mockedResponse {
            return .success(mockedResponse)
        }
        return .failure(mockedError)
    }
}

class DisplayPermissionServiceMock: DisplayPermissionServiceType {
    func checkPermission(forCampaign campaign: CampaignData) -> DisplayPermissionResponse {
        DisplayPermissionResponse(display: true, performPing: false)
    }
}

class ConfigurationManagerMock: ConfigurationManagerType {
    weak var errorDelegate: ErrorDelegate?
    var rolloutPercentage = 100
    var simulateRetryDelay = TimeInterval(0)
    var fetchCalledClosure = {}

    func fetchAndSaveConfigData(completion: @escaping (ConfigData) -> Void) {
        if simulateRetryDelay > 0 {
            let delayMS = Int(simulateRetryDelay * 1000)
            simulateRetryDelay = 0
            WorkScheduler.scheduleTask(milliseconds: delayMS) { [weak self] in
                self?.fetchAndSaveConfigData(completion: completion)
            }
        } else {
            fetchCalledClosure()
            completion(ConfigData(rolloutPercentage: rolloutPercentage, endpoints: .empty))
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
        return connectionStub
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

    func getConfigData() -> Result<ConfigData, ConfigurationServiceError> {
        getConfigDataCallCount += 1

        guard !simulateRequestFailure else {
            return .failure(mockedError)
        }

        return .success(ConfigData(rolloutPercentage: rolloutPercentage, endpoints: .empty))
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
    static var inAppSubscriptionIdMock: String? = "sub-id"

    static func reset() {
        applicationIdMock = "app.id"
        appVersionMock = "1.2.3"
        inAppSdkVersionMock = "0.0.5"
        inAppSubscriptionIdMock = "sub-id"
    }

    override class var applicationId: String? {
        return applicationIdMock
    }

    override class var appVersion: String? {
        return appVersionMock
    }

    override class var inAppSdkVersion: String? {
        return inAppSdkVersionMock
    }

    override class var inAppSubscriptionId: String? {
        return inAppSubscriptionIdMock
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
    var displayedCampaignsCount = 0
    var wasDiscardCampaignCalled = false
    var displayTime = TimeInterval(0.1)

    func displayCampaign(_ campaign: Campaign,
                         associatedImageData: Data?,
                         confirmation: @escaping @autoclosure () -> Bool,
                         completion: @escaping (_ cancelled: Bool) -> Void) {
        guard confirmation() else {
            completion(true)
            return
        }
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                return
            }
            usleep(useconds_t(self.displayTime * Double(USEC_PER_SEC))) // simulate display time
            self.lastDisplayedCampaign = campaign
            self.displayedCampaignsCount += 1
            completion(false)
        }
    }

    func discardDisplayedCampaign() {
        wasDiscardCampaignCalled = true
    }
}

class UserDataCacheMock: UserDataCacheable {
    var userDataMock: UserDataCacheContainer?
    var lastUserDataMock: UserDataCacheContainer?
    var cachedCampaignData: [Campaign]?
    var cachedDisplayPermissionData: (DisplayPermissionResponse, String)?
    var cachedData = [[UserIdentifier]: UserDataCacheContainer]()

    func getUserData(identifiers: [UserIdentifier]) -> UserDataCacheContainer? {
        identifiers == CampaignRepository.lastUser ? lastUserDataMock : userDataMock
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
        return identifiers.map({ $0.identifier }).joined()
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

extension EndpointURL {
    static var empty: Self {
        let emptyURL = URL(string: "about:blank")!
        return EndpointURL(ping: emptyURL,
                           displayPermission: emptyURL,
                           impression: emptyURL)
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
        return [resource]
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

    func didReceiveError(sender: ErrorReportable, error: NSError) {
        wasErrorReceived = true
    }
}