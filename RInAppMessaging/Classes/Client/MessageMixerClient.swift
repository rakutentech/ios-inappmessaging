internal protocol MessageMixerClientType: AnyObject, ErrorReportable {
    /// Starts the first ping to Message Mixer server.
    func ping()
}

/// Class to handle communication with InAppMessaging Message Mixer Server.
internal class MessageMixerClient: MessageMixerClientType, HttpRequestable, TaskSchedulable {

    private let campaignsValidator: CampaignsValidatorType
    private var campaignRepository: CampaignRepositoryType
    private let preferenceRepository: IAMPreferenceRepository
    private let readyCampaignDispatcher: ReadyCampaignDispatcherType
    private let eventMatcher: EventMatcherType
    private let endpointsProvider: () -> EndpointURL?

    weak var errorDelegate: ErrorDelegate?
    var workItemReference: DispatchWorkItem?
    private var retryDelayMillis = 10000 // Milliseconds before pinging Message Mixer server.

    init(campaignsValidator: CampaignsValidatorType,
         campaignRepository: CampaignRepositoryType,
         preferenceRepository: IAMPreferenceRepository,
         readyCampaignDispatcher: ReadyCampaignDispatcherType,
         eventMatcher: EventMatcherType,
         endpointsProvider: @escaping () -> EndpointURL?) {

        self.campaignsValidator = campaignsValidator
        self.campaignRepository = campaignRepository
        self.preferenceRepository = preferenceRepository
        self.readyCampaignDispatcher = readyCampaignDispatcher
        self.eventMatcher = eventMatcher
        self.endpointsProvider = endpointsProvider
    }

    func ping() {
        pingMixerServer()
    }

    /// The function called by the DispatchSourceTimer created in scheduledTimer().
    /// This function handles the HTTP request and parsing the response body.
    private func pingMixerServer() {
        guard let mixerServerUrl = endpointsProvider()?.ping else {
            let error = "InAppMessaging: Error retrieving InAppMessaging Mixer Server URL"
            CommonUtility.debugPrint(error)
            reportError(description: error, data: nil)
            return
        }

        guard let response = try? requestFromServerSync(
            url: mixerServerUrl,
            httpMethod: .post,
            addtionalHeaders: buildRequestHeader()).get().data else {

                WorkScheduler.scheduleTask(milliseconds: retryDelayMillis, closure: pingMixerServer, wallDeadline: true)
                // Exponential backoff for pinging Message Mixer server.
                retryDelayMillis *= 2
                return
        }

        let decodedResponse: PingResponse
        do {
            let decoder = JSONDecoder()
            decodedResponse = try decoder.decode(PingResponse.self, from: response)
        } catch let error {

            let description = "InAppMessaging: Failed to parse json"
            CommonUtility.debugPrint("\(description): \(error)")
            reportError(description: description, data: error)
            return
        }

        CommonUtility.lock(resourcesIn: [campaignRepository]) {
            campaignRepository.syncWith(list: decodedResponse.data,
                                        timestampMilliseconds: decodedResponse.currentPingMillis)
            campaignsValidator.validate(
                validatedCampaignHandler: CampaignsValidatorHelper.defaultValidatedCampaignHandler(
                    eventMatcher: eventMatcher,
                    dispatcher: readyCampaignDispatcher))
        }

        readyCampaignDispatcher.dispatchAllIfNeeded()

        let workItem = DispatchWorkItem { self.pingMixerServer() }
        scheduleWorkItem(decodedResponse.nextPingMillis, task: workItem, wallDeadline: true)
    }
}

// MARK: - HttpRequestable implementation
extension MessageMixerClient {
    /// Request body for Message Mixer Client to hit ping endpoint.
    /// - Parameter optionalParams: Additional parameters to be added to the request body.
    /// - Returns: Optional serialized data for the request body.
    func buildHttpBody(withOptionalParams optionalParams: [String: Any]?) -> Data? {

        guard let appVersion = Bundle.appVersion else {
            reportError(description: "InAppMessaging: failed creating a request body.", data: nil)
            assertionFailure()
            return nil
        }

        let pingRequest = PingRequest(
            userIdentifiers: preferenceRepository.getUserIdentifiers(),
            appVersion: appVersion
        )

        do {
            return try JSONEncoder().encode(pingRequest)
        } catch let error {
            let description = "InAppMessaging: failed creating a request body."
            print("\(description): \(error)")
            reportError(description: description, data: error)
        }

        return nil
    }

    private func buildRequestHeader() -> [Attribute] {
        var additionalHeaders: [Attribute] = []

        // Retrieve sub ID and return in header of the request.
        if let subId = Bundle.inAppSubscriptionId {
            additionalHeaders.append(Attribute(key: Constants.Request.subscriptionHeader, value: subId))
        }

        // Retrieve device ID and return in header of the request.
        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            additionalHeaders.append(Attribute(key: Constants.Request.deviceID, value: deviceId))
        }

        // Retrieve access token and return in the header of the request.
        if let accessToken = preferenceRepository.getAccessToken() {
            additionalHeaders.append(Attribute(key: Constants.Request.authorization, value: "OAuth2 \(accessToken)"))
        }

        return additionalHeaders
    }
}
