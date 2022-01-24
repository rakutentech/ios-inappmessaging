internal protocol CampaignTriggerAgentType {
    func validateAndTriggerCampaigns()
}

internal struct CampaignTriggerAgent: CampaignTriggerAgentType {

    private let eventMatcher: EventMatcherType
    private let campaignDispatcher: CampaignDispatcherType
    private let tooltipDispatcher: TooltipDispatcherType
    private let validator: CampaignsValidatorType

    init(eventMatcher: EventMatcherType,
         readyCampaignDispatcher: CampaignDispatcherType,
         tooltipDispatcher: TooltipDispatcherType,
         campaignsValidator: CampaignsValidatorType) {

        self.eventMatcher = eventMatcher
        self.campaignDispatcher = readyCampaignDispatcher
        self.tooltipDispatcher = tooltipDispatcher
        self.validator = campaignsValidator
    }

    func validateAndTriggerCampaigns() {
        CommonUtility.lock(resourcesIn: [eventMatcher]) {
            validator.validate { (campaign, triggeredEvents) in
                do {
                    try eventMatcher.removeSetOfMatchedEvents(triggeredEvents, for: campaign)
                    if campaign.isTooltip {
                        tooltipDispatcher.setNeedsDisplay(tooltip: campaign)
                    } else {
                        campaignDispatcher.addToQueue(campaignID: campaign.id)
                    }
                } catch {
                    // Campaign is not ready to be displayed
                }
            }
        }
        campaignDispatcher.dispatchAllIfNeeded()
    }
}
