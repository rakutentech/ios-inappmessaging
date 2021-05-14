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
    private(set) var wasResetDataPersistenceCalled = false

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
        wasResetDataPersistenceCalled = false
    }

    func resetDataPersistence() {
        wasResetDataPersistenceCalled = true
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
    var addedCampaigns = [Campaign]()
    var wasResetQueueCalled = false

    func addToQueue(campaign: Campaign) {
        addedCampaigns.append(campaign)
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

class ConfigurationManagerMock: ConfigurationManagerType {
    weak var errorDelegate: ErrorDelegate?
    var rolloutPercentage = 100
    var fetchCalledClosure = {}

    func fetchAndSaveConfigData(completion: @escaping (ConfigData) -> Void) {
        fetchCalledClosure()
        completion(ConfigData(rolloutPercentage: rolloutPercentage, endpoints: .empty))
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

class URLSessionMock: URLSession {

    typealias SessionTaskCompletion = (Data?, URLResponse?, Error?) -> Void

    static var swizzledMethods: (Method, Method)?
    private static var mockSessionLinks = [URLSession: WeakWrapper<URLSessionMock>]()

    private let originalInstance: URLSession?

    @objc var sentRequest: URLRequest?
    var httpResponse: HTTPURLResponse?
    var responseData: Data?
    var responseError: Error?

    static func mock(originalInstance: URLSession) -> URLSessionMock {
        if let existingMock = URLSessionMock.mockSessionLinks[originalInstance]?.value {
            return existingMock
        } else {
            let newMock = URLSessionMock(originalInstance: originalInstance)
            URLSessionMock.mockSessionLinks[originalInstance] = WeakWrapper(value: newMock)
            return newMock
        }
    }

    private init(originalInstance: URLSession) {
        self.originalInstance = originalInstance
        super.init()
    }

    static func startMockingURLSession() {
        guard swizzledMethods == nil else {
            return
        }

        let originalMethod = class_getInstanceMethod(
            URLSession.self,
            #selector(URLSession().dataTask(with:completionHandler:)
                as (URLRequest, @escaping SessionTaskCompletion) -> URLSessionDataTask))!

        let dummyObject = URLSessionMock(originalInstance: URLSession())
        let swizzledMethod = class_getInstanceMethod(
            URLSessionMock.self,
            #selector(dummyObject.dataTask(with:completionHandler:)
                as (URLRequest, @escaping SessionTaskCompletion) -> URLSessionDataTask))!

        swizzledMethods = (originalMethod, swizzledMethod)
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    static func stopMockingURLSession() {
        guard let swizzledMethods = swizzledMethods else {
            return
        }
        method_exchangeImplementations(swizzledMethods.0, swizzledMethods.1)
        self.swizzledMethods = nil
    }

    func decodeSentData<T: Decodable>(modelType: T.Type) -> T? {
        guard let httpBody = sentRequest?.httpBody else {
            return nil
        }
        return try? JSONDecoder().decode(modelType.self, from: httpBody)
    }

    func decodeQueryItems<T: Decodable>(modelType: T.Type) -> T? {
        guard let url = sentRequest?.url,
              let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = urlComponents.queryItems else {
            return nil
        }
        let array = queryItems.map { item -> String? in
            guard let value = item.value else {
                return nil
            }
            if let intValue = Int(value) {
                return "\"\(item.name)\": \(intValue)"
            }
            return "\"\(item.name)\": \"\(value)\""
        }.compactMap { $0 }
        guard let jsonData = "{\(array.joined(separator: ","))}".data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(modelType.self, from: jsonData)
    }

    override func dataTask(
        with request: URLRequest,
        completionHandler: @escaping SessionTaskCompletion) -> URLSessionDataTask {

        let mockedSession: URLSessionMock?
        if self.responds(to: #selector(getter: sentRequest)) {
            mockedSession = self // not swizzled
        } else {
            mockedSession = URLSessionMock.mockSessionLinks[self]?.value
        }

        let originalSession = mockedSession?.originalInstance ?? URLSession.shared
        guard let mockContainer = mockedSession else {
            return originalSession.dataTask(with: request)
        }

        mockContainer.sentRequest = request
        completionHandler(mockContainer.responseData,
                          mockContainer.httpResponse,
                          mockContainer.responseError)

        let dummyRequest = URLRequest(url: URL(string: "about:blank")!)
        // URLSessionDataTask object must be created by an URLSession object
        return originalSession.dataTask(with: dummyRequest)
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

    func deleteUserData(identifiers: [UserIdentifier]) { }
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
