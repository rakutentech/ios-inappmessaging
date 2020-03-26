internal protocol BaseViewPresenterType: ImpressionTrackable {
    var campaign: Campaign! { get set }
    var impressions: [Impression] { get set }
    var associatedImage: UIImage? { get set }

    func viewDidInitialize()
    func handleButtonTrigger(_ trigger: Trigger?)
    func optOutCampaign()
}

internal class BaseViewPresenter: BaseViewPresenterType {

    private(set) var impressionService: ImpressionServiceType
    private let campaignsValidator: CampaignsValidatorType
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

    init(campaignsValidator: CampaignsValidatorType,
         campaignRepository: CampaignRepositoryType,
         impressionService: ImpressionServiceType,
         eventMatcher: EventMatcherType,
         campaignTriggerAgent: CampaignTriggerAgentType) {

        self.campaignsValidator = campaignsValidator
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
        campaignsValidator.validate { campaign, events in
            campaignTriggerAgent.trigger(campaign: campaign, triggeredEvents: events)
        }
    }

    func optOutCampaign() {
        campaign = campaignRepository.optOutCampaign(campaign)
    }
}
