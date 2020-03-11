internal protocol ImpressionClientType: AnyObject, ErrorReportable {

    /// Retrieves the impression URL and sends it to the backend.
    /// Packs up neccessary data to create the request body.
    /// - Parameter impressions: The list of impressions to send.
    /// - Parameter campaignData: The campaign data to parse for fields.
    func pingImpression(impressions: [Impression], campaignData: CampaignData)
}

/// Handles hitting the impression endpoint.
internal class ImpressionClient: ImpressionClientType, HttpRequestable, AnalyticsBroadcaster {

    private let preferenceRepository: IAMPreferenceRepository
    private let endpointsProvider: () -> EndpointURL?

    /// Keys for the optionalParams dictionary.
    private enum Keys {
        static let impression = "impressions"
        static let campaign = "campaign"
    }

    weak var errorDelegate: ErrorDelegate?

    init(preferenceRepository: IAMPreferenceRepository,
         endpointsProvider: @escaping () -> EndpointURL?) {

        self.preferenceRepository = preferenceRepository
        self.endpointsProvider = endpointsProvider
    }

    func pingImpression(impressions: [Impression],
                        campaignData: CampaignData) {

        guard let pingImpressionEndpoint = endpointsProvider()?.impression else {
            let error = "InAppMessaging: Error retrieving InAppMessaging Impression URL"
            CommonUtility.debugPrint(error)
            reportError(description: error, data: nil)
            return
        }

        let optionalParams: [String: Any] = [
            Keys.impression: impressions,
            Keys.campaign: campaignData
        ]

        // Broadcast impression data to RAnalytics.
        sendEventName(
            Constants.RAnalytics.impressions,
            ["impressions": deconstructImpressionObject(impressionList: impressions)]
        )

        // Send impression data back to impression endpoint.
        requestFromServer(
            url: pingImpressionEndpoint,
            httpMethod: .post,
            optionalParams: optionalParams,
            addtionalHeaders: buildRequestHeader(),
            completion: { [weak self] result in
                switch result {
                case .failure(let error):
                    self?.reportError(description: "InAppMessaging: Error sending impressions", data: error)
                default: ()
                }
        })
    }

    /// Deconstruct impression object list to send back to RAnalytics.
    /// This is to solve the issue where RAnalytics cannot take in IAM's custom objects.
    /// - Parameter impressionList: An array of impression objects.
    /// - Returns: An array of primitive impression values.
    private func deconstructImpressionObject(impressionList: [Impression]) -> [Any] {
        var resultList = [Any]()

        for impression in impressionList {
            var tempImpression = [String: Any]()
            tempImpression["action"] =  impression.type.rawValue
            tempImpression["timestamp"] = impression.timestamp

            resultList.append(tempImpression)
        }

        return resultList
    }

    /// Build the request body for hitting the impression endpoint.
    func buildHttpBody(withOptionalParams optionalParams: [String: Any]?) -> Data? {

        guard let params = optionalParams,
            let impressions = params[Keys.impression] as? [Impression],
            let campaign = params[Keys.campaign] as? CampaignData,
            let appVersion = Bundle.appVersion,
            let sdkVersion = Bundle.inAppSdkVersion
        else {

            let error = "InAppMessaging: Error building impressions request body"
            CommonUtility.debugPrint(error)
            reportError(description: error, data: nil)

            return nil
        }

        let impressionRequest = ImpressionRequest(
            campaignId: campaign.campaignId,
            isTest: campaign.isTest,
            appVersion: appVersion,
            sdkVersion: sdkVersion,
            impressions: impressions,
            userIdentifiers: preferenceRepository.getUserIdentifiers()
        )

        do {
            return try JSONEncoder().encode(impressionRequest)
        } catch let error {
            let description = "InAppMessaging: Error encoding impression request"
            CommonUtility.debugPrint("\(description): \(error)")
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

        // Retrieve access token and return in the header of the request.
        if let accessToken = preferenceRepository.getAccessToken() {
            additionalHeaders.append(Attribute(key: Constants.Request.authorization, value: "OAuth2 \(accessToken)"))
        }

        // Retrieve device ID and return in header of the request.
        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            additionalHeaders.append(Attribute(key: Constants.Request.deviceID, value: deviceId))
        }

        return additionalHeaders
    }
}
