import Foundation

internal protocol ImpressionServiceType: ErrorReportable {
    func pingImpression(impressions: [Impression], campaignData: CampaignData)
}

internal class ImpressionService: ImpressionServiceType, HttpRequestable, TaskSchedulable {

    private enum Keys {
        enum Params {
            static let impression = "impressions"
            static let campaign = "campaign"
        }
    }

    private let accountRepository: AccountRepositoryType
    private let configurationRepository: ConfigurationRepositoryType
    private var responseStateMachine = ResponseStateMachine()
    // lazy allows mocking in unit tests
    private lazy var retryDelayMS = Constants.Retry.Default.initialRetryDelayMS

    weak var errorDelegate: ErrorDelegate?
    private(set) var httpSession: URLSession
    var bundleInfo = BundleInfo.self
    var scheduledTask: DispatchWorkItem?
    private let eventLogger: EventLoggerSendable

    init(accountRepository: AccountRepositoryType,
         configurationRepository: ConfigurationRepositoryType,
         eventLogger: EventLoggerSendable) {

        self.accountRepository = accountRepository
        self.configurationRepository = configurationRepository
        self.eventLogger = eventLogger
        httpSession = URLSession(configuration: configurationRepository.defaultHttpSessionConfiguration)
    }

    func pingImpression(impressions: [Impression], campaignData: CampaignData) {

        guard let impressionEndpoint = configurationRepository.getEndpoints()?.impression else {
            eventLogger.logEvent(eventType: .critical, errorCode: Constants.IAMErrorCode.impressionMissingEndpoint.errorCode, errorMessage: Constants.IAMErrorCode.impressionMissingEndpoint.errorMessage)
            reportError(description: "Error retrieving InAppMessaging Impression URL", data: nil)
            return
        }

        let parameters: [String: Any] = [
            Keys.Params.impression: impressions,
            Keys.Params.campaign: campaignData
        ]

        // Broadcast impression data to RAnalytics.
        // `impression` type is sent separately, just after campaign is displayed.
        let impressionData = impressions.filter({ $0.type != .impression }).encodeForAnalytics()
        AnalyticsTracker.sendEventName(Constants.RAnalytics.impressionsEventName,
                                       dataObject: [Constants.RAnalytics.Keys.impressions: impressionData,
                                                    Constants.RAnalytics.Keys.campaignID: campaignData.campaignId,
                                                    Constants.RAnalytics.Keys.subscriptionID: configurationRepository.getSubscriptionID() ?? "n/a"])
        
        sendImpressionRequest(endpoint: impressionEndpoint, parameters: parameters)
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
                        guard self.responseStateMachine.consecutiveErrorCount <= Constants.Retry.retryCount else {
                            eventLogger.logEvent(eventType: .critical, errorCode: Constants.IAMErrorCode.impressionResponseError.errorCode + String(statusCode), errorMessage: Constants.IAMErrorCode.impressionResponseError.errorMessage)
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

        guard let appVersion = bundleInfo.appVersion
        else {
            eventLogger.logEvent(eventType: .warning, errorCode: Constants.IAMErrorCode.impressionMissingEndpoint.errorCode, errorMessage: Constants.IAMErrorCode.impressionMissingEndpoint.errorMessage)
            reportError(description: "Error building impressions request body", data: nil)
            return .failure(RequestError.missingMetadata)
        }
        guard let impressions = parameters?[Keys.Params.impression] as? [Impression],
              let campaign = parameters?[Keys.Params.campaign] as? CampaignData
        else {
            eventLogger.logEvent(eventType: .warning, errorCode: Constants.IAMErrorCode.impressionMissingdParameters.errorCode, errorMessage: Constants.IAMErrorCode.impressionMissingdParameters.errorMessage)
            reportError(description: "Error building impressions request body", data: nil)
            return .failure(RequestError.missingParameters)
        }
        let impressionRequest = ImpressionRequest(
            campaignId: campaign.campaignId,
            isTest: campaign.isTest,
            appVersion: appVersion,
            sdkVersion: Constants.Versions.sdkVersion,
            impressions: impressions,
            userIdentifiers: accountRepository.getUserIdentifiers(),
            rmcSdkVersion: bundleInfo.rmcSdkVersion
        )

        do {
            let body = try JSONEncoder().encode(impressionRequest)
            return .success(body)
        } catch {
            eventLogger.logEvent(eventType: .warning, errorCode: Constants.IAMErrorCode.impressionFailedCreatingRequestBody.errorCode, errorMessage: Constants.IAMErrorCode.impressionFailedCreatingRequestBody.errorMessage)
            reportError(description: "Error encoding impression request", data: error)
            return .failure(error)
        }
    }

    private func buildRequestHeader() -> [HeaderAttribute] {
        var builder = HeaderAttributesBuilder()
        builder.addSubscriptionID(configurationRepository: configurationRepository)
        builder.addDeviceID()
        builder.addAccessToken(accountRepository: accountRepository)

        return builder.build()
    }
}
