import Foundation
#if canImport(RSDKUtils)
import class RSDKUtils.AnalyticsBroadcaster
#else // SPM Version
import class RSDKUtilsMain.AnalyticsBroadcaster
#endif

internal protocol ImpressionServiceType: ErrorReportable {
    func pingImpression(impressions: [Impression], campaignData: CampaignData)
}

internal class ImpressionService: ImpressionServiceType, HttpRequestable, TaskSchedulable {

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

    private let accountRepository: AccountRepositoryType
    private let configurationRepository: ConfigurationRepositoryType
    private var responseStateMachine = ResponseStateMachine()
    private var retryDelayMS = Constants.Retry.Default.initialRetryDelayMS

    weak var errorDelegate: ErrorDelegate?
    private(set) var httpSession: URLSession
    var bundleInfo = BundleInfo.self
    var scheduledTask: DispatchWorkItem?

    init(accountRepository: AccountRepositoryType,
         configurationRepository: ConfigurationRepositoryType) {

        self.accountRepository = accountRepository
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
        AnalyticsBroadcaster.sendEventName(Constants.RAnalytics.impressions,
                                           dataObject: [Keys.Analytics.impressions: encodeForAnalytics(impressionList: impressions)])
        
        sendImpressionRequest(endpoint: impressionEndpoint, parameters: parameters)
    }

    private func encodeForAnalytics(impressionList: [Impression]) -> [Any] {

        return impressionList.map { impression in
            return [Keys.Analytics.action: impression.type.rawValue,
                    Keys.Analytics.timestamp: impression.timestamp]
        }
    }

    private func sendImpressionRequest(endpoint: URL, parameters: [String : Any]) {
        requestFromServer(
            url: endpoint,
            httpMethod: .post,
            parameters: parameters,
            addtionalHeaders: buildRequestHeader(),
            completion: { [weak self] result in
                guard let self = self else {
                    return
                }
                switch result {
                case .success:
                    self.responseStateMachine.push(state: .success)
                    self.retryDelayMS = Constants.Retry.Default.initialRetryDelayMS

                case .failure(let error):
                    self.responseStateMachine.push(state: .error)

                    switch error {
                    case .httpError(let statusCode, _, _) where statusCode >= 500:
                        guard self.responseStateMachine.consecutiveErrorCount < 3 else {
                            return
                        }
                        self.retryImpressionRequest(endpoint: endpoint, parameters: parameters)

                    case .taskFailed:
                        self.retryImpressionRequest(endpoint: endpoint, parameters: parameters)

                    default: ()
                    }
                }
        })
    }

    private func retryImpressionRequest(endpoint: URL, parameters: [String : Any]) {
        scheduleTask(milliseconds: Int(retryDelayMS), wallDeadline: true) { [weak self] in
            self?.sendImpressionRequest(endpoint: endpoint, parameters: parameters)
        }
        retryDelayMS.increaseBackOff()
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
            userIdentifiers: accountRepository.getUserIdentifiers()
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
        builder.addAccessToken(accountRepository: accountRepository)

        return builder.build()
    }
}
