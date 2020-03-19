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

    func addToQueue(campaign: Campaign) { }
    func dispatchAllIfNeeded() {
        wasDispatchCalled = true
    }
}

class EventMatcherMock: EventMatcherType {
    private(set) var loggedEvents = [Event]()
    func matchAndStore(event: Event) {
        loggedEvents.append(event)
    }

    func matchedEvents(for campaign: Campaign) -> [Event] { return [] }
    func containsAllMatchedEvents(for campaign: Campaign) -> Bool { return true }
    func removeSetOfMatchedEvents(_ eventsToRemove: Set<Event>, for campaign: Campaign) throws { }
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

class ConfigurationRepositoryMock: ConfigurationRepositoryType {
    var defaultHttpSessionConfiguration: URLSessionConfiguration = .ephemeral
    var configuration: ConfigData?

    func saveConfiguration(_ data: ConfigData) {
        configuration = data
    }

    func getEndpoints() -> EndpointURL? {
        return configuration?.endpoints
    }

    func getIsEnabledStatus() -> Bool? {
        return configuration?.enabled
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
