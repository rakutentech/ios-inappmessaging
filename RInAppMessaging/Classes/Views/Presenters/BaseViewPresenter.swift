import class UIKit.UIAlertAction

internal protocol BaseViewPresenterType: ImpressionTrackable {
    var campaign: Campaign! { get set }
    var impressions: [Impression] { get set }
    var associatedImage: UIImage? { get set }

    func viewDidInitialize()
    func handleButtonTrigger(_ trigger: Trigger?)
    func optOutCampaign()
    func loadResources()
}

internal class BaseViewPresenter: BaseViewPresenterType {

    private(set) var impressionService: ImpressionServiceType
    private let campaignRepository: CampaignRepositoryType
    private let eventMatcher: EventMatcherType
    private let campaignTriggerAgent: CampaignTriggerAgentType

    var campaign: Campaign!
    var impressions: [Impression] = []
    lazy var associatedImage: UIImage? = {
        guard let imageURLString = campaign.data.messagePayload.resource.imageUrl,
            let encodedImageURLString = imageURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let encodedImageURL = URL(string: encodedImageURLString),
            let imageData = try? Data(contentsOf: encodedImageURL) else {

            return nil
        }
        return UIImage(data: imageData)
    }()

    init(campaignRepository: CampaignRepositoryType,
         impressionService: ImpressionServiceType,
         eventMatcher: EventMatcherType,
         campaignTriggerAgent: CampaignTriggerAgentType) {

        self.impressionService = impressionService
        self.eventMatcher = eventMatcher
        self.campaignRepository = campaignRepository
        self.campaignTriggerAgent = campaignTriggerAgent
    }

    /// To be called by associated view after init
    func viewDidInitialize() {}

    func sendImpressions() {
        sendImpressions(for: campaign)
        impressions.removeAll()
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

    func loadResources() {
        // load image from imageUrl data
        _ = associatedImage
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
