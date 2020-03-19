internal protocol ImpressionServiceType: ErrorReportable {
    func pingImpression(impressions: [Impression], campaignData: CampaignData)
}

internal class ImpressionService: ImpressionServiceType, HttpRequestable, AnalyticsBroadcaster {

    private enum Keys {
        enum Params {
            static let impression = "impressions"
            static let campaign = "campaign"
        }
        enum Analytics {
            static let impressions = "impressions"
            static let action = "action"
            static let timestamp = "timestamp"
        }
    }

    private let preferenceRepository: IAMPreferenceRepository
    private let configurationRepository: ConfigurationRepositoryType

    weak var errorDelegate: ErrorDelegate?
    private(set) var httpSession: URLSession
    var bundleInfo = BundleInfo.self

    init(preferenceRepository: IAMPreferenceRepository,
         configurationRepository: ConfigurationRepositoryType) {

        self.preferenceRepository = preferenceRepository
        self.configurationRepository = configurationRepository
        httpSession = URLSession(configuration: configurationRepository.defaultHttpSessionConfiguration)
    }

    func pingImpression(impressions: [Impression], campaignData: CampaignData) {

        guard let pingImpressionEndpoint = configurationRepository.getEndpoints()?.impression else {
            let error = "InAppMessaging: Error retrieving InAppMessaging Impression URL"
            CommonUtility.debugPrint(error)
            reportError(description: error, data: nil)
            return
        }

        let parameters: [String: Any] = [
            Keys.Params.impression: impressions,
            Keys.Params.campaign: campaignData
        ]

        // Broadcast impression data to RAnalytics.
        sendEventName(
            Constants.RAnalytics.impressions,
            [Keys.Analytics.impressions: encodeForAnalytics(impressionList: impressions)]
        )

        requestFromServer(
            url: pingImpressionEndpoint,
            httpMethod: .post,
            parameters: parameters,
            addtionalHeaders: buildRequestHeader(),
            completion: { [weak self] result in

                if case .failure(let error) = result {
                    self?.reportError(description: "InAppMessaging: Error sending impressions",
                                      data: error)
                }
        })
    }

    private func encodeForAnalytics(impressionList: [Impression]) -> [Any] {

        return impressionList.map { impression in
            return [Keys.Analytics.action: impression.type.rawValue,
                    Keys.Analytics.timestamp: impression.timestamp]
        }
    }
}

// MARK: - HttpRequestable implementation
extension ImpressionService {

    func buildHttpBody(with parameters: [String: Any]?) -> Result<Data, Error> {

        guard let parameters = parameters,
            let impressions = parameters[Keys.Params.impression] as? [Impression],
            let campaign = parameters[Keys.Params.campaign] as? CampaignData,
            let appVersion = bundleInfo.appVersion,
            let sdkVersion = bundleInfo.inAppSdkVersion
            else {

                let error = "InAppMessaging: Error building impressions request body"
                CommonUtility.debugPrint(error)
                reportError(description: error, data: nil)

                return .failure(RequestError.unknown)
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
            let body = try JSONEncoder().encode(impressionRequest)
            return .success(body)
        } catch {
            let description = "InAppMessaging: Error encoding impression request"
            CommonUtility.debugPrint("\(description): \(error)")
            reportError(description: description, data: error)
            return .failure(error)
        }
    }

    private func buildRequestHeader() -> [Attribute] {
        let Keys = Constants.Request.Header.self
        var additionalHeaders: [Attribute] = []

        if let subId = bundleInfo.inAppSubscriptionId {
            additionalHeaders.append(Attribute(key: Keys.subscriptionID, value: subId))
        }

        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            additionalHeaders.append(Attribute(key: Keys.deviceID, value: deviceId))
        }

        return additionalHeaders
    }
}
