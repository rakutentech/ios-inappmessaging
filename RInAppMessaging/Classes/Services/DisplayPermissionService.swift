internal protocol DisplayPermissionServiceType {
    func checkPermission(forCampaign campaign: CampaignData) -> DisplayPermissionResponse
}

internal class DisplayPermissionService: DisplayPermissionServiceType, HttpRequestable {

    private let campaignRepository: CampaignRepositoryType
    private let preferenceRepository: IAMPreferenceRepository
    private let configurationRepository: ConfigurationRepositoryType

    private(set) var httpSession: URLSession
    private(set) var lastResponse: RequestResult?
    var bundleInfo = BundleInfo.self

    init(campaignRepository: CampaignRepositoryType,
         preferenceRepository: IAMPreferenceRepository,
         configurationRepository: ConfigurationRepositoryType) {

        self.campaignRepository = campaignRepository
        self.preferenceRepository = preferenceRepository
        self.configurationRepository = configurationRepository
        httpSession = URLSession(configuration: configurationRepository.defaultHttpSessionConfiguration)
    }

    func checkPermission(forCampaign campaign: CampaignData) -> DisplayPermissionResponse {
        // In case of error allow campaigns to be displayed anyway
        let fallbackResponse = DisplayPermissionResponse(display: true, performPing: false)
        let requestParams = [
            Constants.Request.campaignID: campaign.campaignId
        ]

        guard let displayPermissionUrl = configurationRepository.getEndpoints()?.displayPermission else {
            CommonUtility.debugPrint("error: missing endpoint for DisplayPermissionService")
            return fallbackResponse
        }

        let responseData = requestFromServerSync(url: displayPermissionUrl,
                                                 httpMethod: .post,
                                                 parameters: requestParams,
                                                 addtionalHeaders: buildRequestHeader())
        lastResponse = responseData

        guard let responseFromDisplayPermission = try? responseData.get() else {
            CommonUtility.debugPrint("error getting a response from display permission.")
            return fallbackResponse
        }

        do {
            let decodedResponse = try JSONDecoder().decode(DisplayPermissionResponse.self,
                                                           from: responseFromDisplayPermission.data)
            return decodedResponse
        } catch {
            CommonUtility.debugPrint("error getting a response from display permission.")
        }

        return fallbackResponse
    }
}

// MARK: - HttpRequestable implementation
extension DisplayPermissionService {

    func buildHttpBody(with parameters: [String: Any]?) -> Result<Data, Error> {

        guard let subscriptionId = bundleInfo.inAppSubscriptionId,
              let appVersion = bundleInfo.appVersion,
              let sdkVersion = bundleInfo.inAppSdkVersion
        else {
            CommonUtility.debugPrint("error while building request body for display permssion - missing metadata")
            return .failure(RequestError.missingMetadata)
        }
        guard let campaignId = parameters?[Constants.Request.campaignID] as? String else {
            CommonUtility.debugPrint("error while building request body for display permssion - unexpected parameters")
            return .failure(RequestError.missingParameters)
        }

        let permissionRequest = DisplayPermissionRequest(subscriptionId: subscriptionId,
                                                         campaignId: campaignId,
                                                         userIdentifiers: preferenceRepository.getUserIdentifiers(),
                                                         platform: .ios,
                                                         appVersion: appVersion,
                                                         sdkVersion: sdkVersion,
                                                         locale: Locale.current.normalizedIdentifier,
                                                         lastPingInMilliseconds: campaignRepository.lastSyncInMilliseconds ?? 0)
        do {
            let body = try JSONEncoder().encode(permissionRequest)
            return .success(body)
        } catch {
            CommonUtility.debugPrint("failed creating a request body.")
            return .failure(error)
        }
    }

    private func buildRequestHeader() -> [HeaderAttribute] {
        let Keys = Constants.Request.Header.self
        var additionalHeaders: [HeaderAttribute] = []

        if let subId = bundleInfo.inAppSubscriptionId {
            additionalHeaders.append(HeaderAttribute(key: Keys.subscriptionID, value: subId))
        }

        if let accessToken = preferenceRepository.getAccessToken() {
            additionalHeaders.append(HeaderAttribute(key: Keys.authorization, value: "OAuth2 \(accessToken)"))
        }

        return additionalHeaders
    }
}
