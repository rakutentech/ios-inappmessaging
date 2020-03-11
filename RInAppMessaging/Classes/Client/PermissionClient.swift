internal protocol PermissionClientType {

    /// Handle communicating with the display_permission endpoint and handling the response.
    /// By default, if anything goes wrong with the communication, return true and show the campaign.
    /// - Parameter campaign: Campaign that is about to be shown.
    /// - Returns: A flag to signal the SDK to either show or don't show the campaign.
    func checkPermission(withCampaign campaign: CampaignData) -> Bool
}

/// Struct to handle permission checking before displaying a campaign.
internal struct PermissionClient: PermissionClientType, HttpRequestable {

    private let campaignRepository: CampaignRepositoryType
    private let preferenceRepository: IAMPreferenceRepository
    private let pingActionHandler: () -> Void
    private let endpointsProvider: () -> EndpointURL?

    init(campaignRepository: CampaignRepositoryType,
         preferenceRepository: IAMPreferenceRepository,
         pingActionHandler: @escaping () -> Void,
         endpointsProvider: @escaping () -> EndpointURL?) {

        self.campaignRepository = campaignRepository
        self.pingActionHandler = pingActionHandler
        self.preferenceRepository = preferenceRepository
        self.endpointsProvider = endpointsProvider
    }

    func checkPermission(withCampaign campaign: CampaignData) -> Bool {

        let requestParams = [
            Constants.Request.campaignID: campaign.campaignId
        ]

        // Call display-permission endpoint.
        guard let displayPermissionUrl = endpointsProvider()?.displayPermission,
            let responseFromDisplayPermission = try? requestFromServerSync(
                                                        url: displayPermissionUrl,
                                                        httpMethod: .post,
                                                        optionalParams: requestParams,
                                                        addtionalHeaders: buildRequestHeader()).get().data
        else {
            CommonUtility.debugPrint("InAppMessaging: error getting a response from display permission.")
            return true
        }

        // Parse and handle the response.
        do {
            let decodedResponse = try JSONDecoder().decode(DisplayPermissionResponse.self, from: responseFromDisplayPermission)

            if decodedResponse.performPing {
                // Perform a re-ping.
                pingActionHandler()
            }

            // Return the response from the display_permission endpoint.
            return decodedResponse.display

        } catch {
            CommonUtility.debugPrint("InAppMessaging: error getting a response from display permission.")
        }

        return true
    }

    /// Request body for display permission check.
    /// - Parameter optionalParams: Additional params to be added to the request body.
    /// - Returns: Optional serialized data for the request body.
    func buildHttpBody(withOptionalParams optionalParams: [String: Any]?) -> Data? {

        guard let subscriptionId = Bundle.inAppSubscriptionId,
            let campaignId = optionalParams?[Constants.Request.campaignID] as? String,
            let appVersion = Bundle.appVersion,
            let sdkVersion = Bundle.inAppSdkVersion,
            let locale = Locale.formattedCode
        else {
            CommonUtility.debugPrint("InAppMessaging: error while building request body for display permssion.")
            return nil
        }

        let permissionRequest = DisplayPermissionRequest(subscriptionId: subscriptionId,
                                                         campaignId: campaignId,
                                                         userIdentifiers: preferenceRepository.getUserIdentifiers(),
                                                         platform: PlatformEnum.ios.rawValue,
                                                         appVersion: appVersion,
                                                         sdkVersion: sdkVersion,
                                                         locale: locale,
                                                         lastPingInMillis: campaignRepository.lastSyncInMilliseconds ?? 0)
        do {
            return try JSONEncoder().encode(permissionRequest)
        } catch {
            CommonUtility.debugPrint("InAppMessaging: failed creating a request body.")
        }

        return nil
    }

    private func buildRequestHeader() -> [Attribute] {
        var additionalHeaders: [Attribute] = []

        // Retrieve sub ID and return in header of the request.
        if let subId = Bundle.inAppSubscriptionId {
            additionalHeaders.append(Attribute(key: Constants.Request.subscriptionHeader, value: subId))
        }

        // Retrieve access token and return in the header of the request.
        if let accessToken = preferenceRepository.getAccessToken() {
            additionalHeaders.append(Attribute(key: Constants.Request.authorization, value: "OAuth2 \(accessToken)"))
        }

        return additionalHeaders
    }
}
