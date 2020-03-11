/// Class represents bootstrap behaviour and main functionality of InAppMessaging.
internal class InAppMessagingModule: ErrorDelegate, AnalyticsBroadcaster {

    private let configurationClient: ConfigurationClient
    private var messageMixerClient: MessageMixerClientType
    private let preferenceRepository: IAMPreferenceRepository
    private let campaignsValidator: CampaignsValidatorType
    private let eventMatcher: EventMatcherType
    private let readyCampaignDispatcher: ReadyCampaignDispatcherType
    private var impressionClient: ImpressionClientType

    var aggregatedErrorHandler: ((NSError) -> Void)?

    private(set) var isInitialized = false

    init(configurationClient: ConfigurationClient,
         messageMixerClient: MessageMixerClientType,
         impressionClient: ImpressionClientType,
         preferenceRepository: IAMPreferenceRepository,
         campaignsValidator: CampaignsValidatorType,
         eventMatcher: EventMatcherType,
         readyCampaignDispatcher: ReadyCampaignDispatcherType) {

        self.configurationClient = configurationClient
        self.messageMixerClient = messageMixerClient
        self.preferenceRepository = preferenceRepository
        self.campaignsValidator = campaignsValidator
        self.eventMatcher = eventMatcher
        self.readyCampaignDispatcher = readyCampaignDispatcher
        self.impressionClient = impressionClient

        self.configurationClient.errorDelegate = self
        self.messageMixerClient.errorDelegate = self
        self.impressionClient.errorDelegate = self
    }

    /// Function to initialize InAppMessaging Module.
    /// - Parameter restartHandler: Code to be exetuted in case of failed initialization.
    func initialize(restartHandler: @escaping () -> Void) {
        // Return and exit thread if SDK were to be disabled.
        guard !isInitialized && configurationClient.isConfigEnabled(retryHandler: restartHandler) else {
            return
        }

        isInitialized = true

        // Enable MessageMixerClient which starts beacon pinging message mixer server.
        messageMixerClient.ping()
    }

    func logEvent(_ event: Event) {
        guard isInitialized else {
            return
        }

        eventMatcher.matchAndStore(event: event)
        sendEventName(Constants.RAnalytics.events, event.analyticsParameters)

        campaignsValidator.validate(
            validatedCampaignHandler: CampaignsValidatorHelper.defaultValidatedCampaignHandler(
                eventMatcher: eventMatcher,
                dispatcher: readyCampaignDispatcher))
        readyCampaignDispatcher.dispatchAllIfNeeded()
    }

    func registerPreference(_ preference: IAMPreference?) {
        preferenceRepository.setPreference(preference)

        guard isInitialized else {
            return
        }

        // Everytime a new ID is registered, send a ping request.
        messageMixerClient.ping()
    }

    func didReceiveError(sender: ErrorReportable, error: NSError) {
        aggregatedErrorHandler?(error)
    }
}
