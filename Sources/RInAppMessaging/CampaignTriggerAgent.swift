internal protocol CampaignTriggerAgentType {
    func validateAndTriggerCampaigns()
}

internal struct CampaignTriggerAgent: CampaignTriggerAgentType {

    private let eventMatcher: EventMatcherType
    private let dispatcher: CampaignDispatcherType
    private let validator: CampaignsValidatorType

    init(eventMatcher: EventMatcherType,
         readyCampaignDispatcher: CampaignDispatcherType,
         campaignsValidator: CampaignsValidatorType) {

        self.eventMatcher = eventMatcher
        self.dispatcher = readyCampaignDispatcher
        self.validator = campaignsValidator
    }

    func validateAndTriggerCampaigns() {
        CommonUtility.lock(resourcesIn: [eventMatcher]) {
            validator.validate { (campaign, triggeredEvents) in
                do {
                    try eventMatcher.removeSetOfMatchedEvents(triggeredEvents, for: campaign)
                    dispatcher.addToQueue(campaignID: campaign.id)
                } catch {
                    // Campaign is not ready to be displayed
                }
            }
        }
        dispatcher.dispatchAllIfNeeded()
    }
}
