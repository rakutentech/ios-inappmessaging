import UIKit
#if canImport(RSDKUtils)
import class RSDKUtils.AnalyticsBroadcaster
#else // SPM Version
import class RSDKUtilsMain.AnalyticsBroadcaster
#endif

internal protocol BaseViewPresenterType: ImpressionTrackable {
    var campaign: Campaign! { get set }
    var associatedImage: UIImage? { get set }

    func viewDidInitialize()
    func handleButtonTrigger(_ trigger: Trigger?)
    func optOutCampaign()
}

internal class BaseViewPresenter: BaseViewPresenterType {

    private(set) var impressionService: ImpressionServiceType
    private let campaignRepository: CampaignRepositoryType
    private let eventMatcher: EventMatcherType
    private let campaignTriggerAgent: CampaignTriggerAgentType
    let configurationRepository: ConfigurationRepositoryType

    var campaign: Campaign!
    var impressions: [Impression] = []
    var associatedImage: UIImage?

    init(campaignRepository: CampaignRepositoryType,
         impressionService: ImpressionServiceType,
         eventMatcher: EventMatcherType,
         campaignTriggerAgent: CampaignTriggerAgentType,
         configurationRepository: ConfigurationRepositoryType) {

        self.impressionService = impressionService
        self.eventMatcher = eventMatcher
        self.campaignRepository = campaignRepository
        self.campaignTriggerAgent = campaignTriggerAgent
        self.configurationRepository = configurationRepository
    }

    func viewDidInitialize() {
        // To be called by associated view after init
    }

    func handleButtonTrigger(_ trigger: Trigger?) {
        guard let trigger = trigger else {
            return
        }
        eventMatcher.matchAndStore(event: CommonUtility.convertTriggerObjectToCustomEvent(trigger))
        campaignTriggerAgent.validateAndTriggerCampaigns()
    }

    func optOutCampaign() {
        campaign = campaignRepository.optOutCampaign(campaign)
    }

    func showURLError(view: BaseView) {
        view.showAlert(title: "dialog_alert_invalidURI_title".localized,
                       message: "dialog_alert_invalidURI_message".localized,
                       style: .alert,
                       actions: [UIAlertAction(title: "dialog_alert_invalidURI_close".localized,
                                               style: .default,
                                               handler: nil)
        ])
    }
}

// MARK: - ImpressionTrackable
extension BaseViewPresenter {
    func sendImpressions() {
        sendImpressions(for: campaign)
        impressions.removeAll()
    }

    func logImpression(type: ImpressionType) {
        let impression = Impression(
            type: type,
            timestamp: Date().millisecondsSince1970
        )
        impressions.append(impression)

        guard type == .impression else {
            return
        }
        // Broadcast only `impression` type here. Other types are sent after campaign is closed.
        let impressionData = [impression].encodeForAnalytics()
        AnalyticsBroadcaster.sendEventName(Constants.RAnalytics.impressionsEventName,
                                           dataObject: [Constants.RAnalytics.Keys.impressions: impressionData,
                                                        Constants.RAnalytics.Keys.campaignID: campaign.id,
                                                        Constants.RAnalytics.Keys.subscriptionID: configurationRepository.getSubscriptionID() ?? "n/a"])
    }
}
