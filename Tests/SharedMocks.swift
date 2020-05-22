@testable import RInAppMessaging

class CampaignsValidatorMock: CampaignsValidatorType {
    private(set) var wasValidateCalled = false

    func validate(validatedCampaignHandler: (Campaign, Set<Event>) -> Void) {
        wasValidateCalled = true
    }
}

class CampaignRepositoryMock: CampaignRepositoryType {
    var list: [Campaign] = []
    var lastSyncInMilliseconds: Int64?
    var resourcesToLock: [LockableResource] = []

    private(set) var wasDecrementImpressionsCalled = false
    private(set) var wasOptOutCalled = false
    private(set) var lastSyncCampaigns = [Campaign]()

    func decrementImpressionsLeftInCampaign(_ campaign: Campaign) -> Campaign? {
        wasDecrementImpressionsCalled = true
        return Campaign.updatedCampaign(campaign, withImpressionLeft: campaign.impressionsLeft - 1)
    }

    func optOutCampaign(_ campaign: Campaign) -> Campaign? {
        wasOptOutCalled = true
        return Campaign.updatedCampaign(campaign, asOptedOut: true)
    }

    func syncWith(list: [Campaign], timestampMilliseconds: Int64) {
        lastSyncCampaigns = list
    }
}

class ReadyCampaignDispatcherMock: ReadyCampaignDispatcherType {
    weak var delegate: ReadyCampaignDispatcherDelegate?
    private(set) var wasDispatchCalled = false
    private(set) var addedCampaigns = [Campaign]()

    func addToQueue(campaign: Campaign) {
        addedCampaigns.append(campaign)
    }
    func dispatchAllIfNeeded() {
        wasDispatchCalled = true
    }
}

class EventMatcherMock: EventMatcherType {
    private(set) var loggedEvents = [Event]()
    var simulateMatchingSuccess = true
    var simulateMatcherError: EventMatcherError?

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
}

class MessageMixerServiceMock: MessageMixerServiceType {
    var wasPingCalled = false
    var mockedResponse: PingResponse?
    var mockedError = MessageMixerServiceError.invalidConfiguration

    func ping() -> Result<PingResponse, MessageMixerServiceError> {
        self.wasPingCalled = true
        if let mockedResponse = mockedResponse {
            return .success(mockedResponse)
        }
        return .failure(mockedError)
    }
}

class ConfigurationManagerMock: ConfigurationManagerType {
    weak var errorDelegate: ErrorDelegate?
    var isConfigEnabled = true
    var fetchCalledClosure = {}

    func fetchAndSaveConfigData(completion: @escaping (ConfigData) -> Void) {
        fetchCalledClosure()
        completion(ConfigData(enabled: isConfigEnabled, endpoints: .empty))
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

    func getConfigData() -> Result<ConfigData, ConfigurationServiceError> {
        getConfigDataCallCount += 1

        guard !simulateRequestFailure else {
            return .failure(.requestError(.unknown))
        }

        return .success(ConfigData(enabled: true, endpoints: .empty))
    }
}

class CampaignTriggerAgentMock: CampaignTriggerAgentType {
    func trigger(campaign: Campaign, triggeredEvents: Set<Event>) { }
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
    private static var mockSessionLinks = [URLSession: URLSessionMock]()

    private let originalInstance: URLSession?

    @objc var sentRequest: URLRequest?
    var httpResponse: HTTPURLResponse?
    var responseData: Data?
    var responseError: Error?

    init(originalInstance: URLSession?) {
        self.originalInstance = originalInstance
        super.init()

        if let unwrappedOriginalInstance = originalInstance {
            URLSessionMock.mockSessionLinks[unwrappedOriginalInstance] = self
        }
    }

    deinit {
        if let originalInstance = originalInstance {
            URLSessionMock.mockSessionLinks.removeValue(forKey: originalInstance)
        }
    }

    static func startMockingURLSession() {
        guard swizzledMethods == nil else {
            return
        }

        let originalMethod = class_getInstanceMethod(
            URLSession.self,
            #selector(URLSession().dataTask(with:completionHandler:)
                as (URLRequest, @escaping SessionTaskCompletion) -> URLSessionDataTask))!

        let dummyObject = URLSessionMock(originalInstance: nil)
        let swizzledMethod = class_getInstanceMethod(
            URLSessionMock.self,
            #selector(dummyObject.dataTask(with:completionHandler:)
                as (URLRequest, @escaping SessionTaskCompletion) -> URLSessionDataTask))!

        method_exchangeImplementations(originalMethod, swizzledMethod)
        swizzledMethods = (originalMethod, swizzledMethod)
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

    override func dataTask(
        with request: URLRequest,
        completionHandler: @escaping SessionTaskCompletion) -> URLSessionDataTask {

        let mockedSession: URLSessionMock?
        if self.responds(to: #selector(getter: sentRequest)) {
            mockedSession = self //not swizzled
        } else {
            mockedSession = URLSessionMock.mockSessionLinks[self]
        }

        guard let mockContainer = mockedSession else {
            return URLSessionDataTask()
        }

        mockContainer.sentRequest = request
        completionHandler(mockContainer.responseData,
                          mockContainer.httpResponse,
                          mockContainer.responseError)

        return URLSessionDataTask()
    }
}

class BundleInfoMock: BundleInfo {
    class override var applicationId: String! {
        return "app.id"
    }

    class override var appVersion: String! {
        return "1.2.3"
    }

    class override var inAppSdkVersion: String! {
        return "0.0.5"
    }

    class override var inAppSubscriptionId: String! {
        return "sub-id"
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
