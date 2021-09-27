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

        guard let impressionEndpoint = configurationRepository.getEndpoints()?.impression else {
            reportError(description: "Error retrieving InAppMessaging Impression URL", data: nil)
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
            url: impressionEndpoint,
            httpMethod: .post,
            parameters: parameters,
            addtionalHeaders: buildRequestHeader(),
            completion: { [weak self] result in

                if case .failure(let error) = result {
                    self?.reportError(description: "Error sending impressions",
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

        guard let appVersion = bundleInfo.appVersion,
              let sdkVersion = bundleInfo.inAppSdkVersion
        else {
            reportError(description: "Error building impressions request body", data: nil)
            return .failure(RequestError.missingMetadata)
        }
        guard let impressions = parameters?[Keys.Params.impression] as? [Impression],
              let campaign = parameters?[Keys.Params.campaign] as? CampaignData
        else {
            reportError(description: "Error building impressions request body", data: nil)
            return .failure(RequestError.missingParameters)
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
            reportError(description: "Error encoding impression request", data: error)
            return .failure(error)
        }
    }

    private func buildRequestHeader() -> [HeaderAttribute] {
        var builder = HeaderAttributesBuilder()
        builder.addSubscriptionID(bundleInfo: bundleInfo)
        builder.addDeviceID()
        builder.addAccessToken(preferenceRepository: preferenceRepository)

        return builder.build()
    }
}
