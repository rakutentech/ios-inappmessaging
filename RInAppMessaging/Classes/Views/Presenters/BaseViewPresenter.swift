/// Base presenter class (abstract) for all of IAM's supported campaign presenters.
internal class BaseViewPresenter: ImpressionTrackable {

    private(set) var impressionClient: ImpressionClientType
    private let campaignsValidator: CampaignsValidatorType
    private let campaignRepository: CampaignRepositoryType
    private let eventMatcher: EventMatcherType
    private let readyCampaignDispatcher: ReadyCampaignDispatcherType

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
         impressionClient: ImpressionClientType,
         eventMatcher: EventMatcherType,
         readyCampaignDispatcher: ReadyCampaignDispatcherType) {

        self.campaignsValidator = campaignsValidator
        self.impressionClient = impressionClient
        self.eventMatcher = eventMatcher
        self.campaignRepository = campaignRepository
        self.readyCampaignDispatcher = readyCampaignDispatcher
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
        campaignsValidator.validate(
            validatedCampaignHandler: CampaignsValidatorHelper.defaultValidatedCampaignHandler(
                eventMatcher: eventMatcher,
                dispatcher: readyCampaignDispatcher))
    }

    func optOutCampaign() {
        campaign = campaignRepository.optOutCampaign(campaign)
    }
}
