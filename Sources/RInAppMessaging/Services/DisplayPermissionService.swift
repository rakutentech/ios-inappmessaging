import Foundation

internal protocol DisplayPermissionServiceType: ErrorReportable {
    func checkPermission(forCampaign campaign: CampaignData) -> DisplayPermissionResponse
}

internal class DisplayPermissionService: DisplayPermissionServiceType, HttpRequestable {

    private let campaignRepository: CampaignRepositoryType
    private let accountRepository: AccountRepositoryType
    private let configurationRepository: ConfigurationRepositoryType

    private(set) var httpSession: URLSession
    private(set) var lastResponse: RequestResult?
    var bundleInfo = BundleInfo.self
    weak var errorDelegate: ErrorDelegate?

    init(campaignRepository: CampaignRepositoryType,
         accountRepository: AccountRepositoryType,
         configurationRepository: ConfigurationRepositoryType) {

        self.campaignRepository = campaignRepository
        self.accountRepository = accountRepository
        self.configurationRepository = configurationRepository
        httpSession = URLSession(configuration: configurationRepository.defaultHttpSessionConfiguration)
    }

    func checkPermission(forCampaign campaign: CampaignData) -> DisplayPermissionResponse {
        checkPermission(forCampaign: campaign, retry: true)
    }

    private func checkPermission(forCampaign campaign: CampaignData, retry: Bool) -> DisplayPermissionResponse {
        // In case of error, disallow campaign display
        let fallbackResponse = DisplayPermissionResponse(display: false, performPing: false)
        let requestParams = [
            Constants.Request.campaignID: campaign.campaignId
        ]

        guard let displayPermissionUrl = configurationRepository.getEndpoints()?.displayPermission else {
            Logger.debug("error: missing endpoint for DisplayPermissionService")
            return fallbackResponse
        }

        let responseResult = requestFromServerSync(url: displayPermissionUrl,
                                                   httpMethod: .post,
                                                   parameters: requestParams,
                                                   addtionalHeaders: buildRequestHeader())
        lastResponse = responseResult

        switch responseResult {
        case .success(let displayPermission):
            do {
                let decodedResponse = try JSONDecoder().decode(DisplayPermissionResponse.self,
                                                               from: displayPermission.data)
                return decodedResponse
            } catch {
                break
            }

        case .failure(let error):
            guard retry else {
                break
            }
            switch error {
            case .httpError(let statusCode, _, _) where statusCode >= 500:
                return checkPermission(forCampaign: campaign, retry: false)

            case .taskFailed:
                return checkPermission(forCampaign: campaign, retry: false)

            default: ()
            }
        }

        reportError(description: "couldn't get a valid response from display permission endpoint", data: nil)
        return fallbackResponse
    }
}

// MARK: - HttpRequestable implementation
extension DisplayPermissionService {

    func buildHttpBody(with parameters: [String: Any]?) -> Result<Data, Error> {

        guard let subscriptionId = configurationRepository.getSubscriptionID(),
              let appVersion = bundleInfo.appVersion else {
            Logger.debug("error while building request body for display permssion - missing metadata")
            return .failure(RequestError.missingMetadata)
        }
        guard let campaignId = parameters?[Constants.Request.campaignID] as? String else {
            Logger.debug("error while building request body for display permssion - unexpected parameters")
            return .failure(RequestError.missingParameters)
        }

        let permissionRequest = DisplayPermissionRequest(subscriptionId: subscriptionId,
                                                         campaignId: campaignId,
                                                         userIdentifiers: accountRepository.getUserIdentifiers(),
                                                         platform: .ios,
                                                         appVersion: appVersion,
                                                         sdkVersion: Constants.Versions.sdkVersion,
                                                         locale: Locale.current.normalizedIdentifier,
                                                         lastPingInMilliseconds: campaignRepository.lastSyncInMilliseconds ?? 0,
                                                         rmcSdkVersion: bundleInfo.rmcSdkVersion)
        do {
            let body = try JSONEncoder().encode(permissionRequest)
            return .success(body)
        } catch {
            Logger.debug("failed creating a request body.")
            return .failure(error)
        }
    }

    private func buildRequestHeader() -> [HeaderAttribute] {
        var builder = HeaderAttributesBuilder()
        builder.addSubscriptionID(configurationRepository: configurationRepository)
        builder.addAccessToken(accountRepository: accountRepository)
        builder.addDeviceID()
        
        return builder.build()
    }
}
