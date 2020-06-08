internal protocol CampaignTriggerAgentType {
    func trigger(campaign: Campaign, triggeredEvents: Set<Event>)
}

internal struct CampaignTriggerAgent: CampaignTriggerAgentType {

    private let eventMatcher: EventMatcherType
    private let dispatcher: CampaignDispatcherType

    init(eventMatcher: EventMatcherType,
         readyCampaignDispatcher: CampaignDispatcherType) {

        self.eventMatcher = eventMatcher
        self.dispatcher = readyCampaignDispatcher
    }

    func trigger(campaign: Campaign, triggeredEvents: Set<Event>) {
        do {
            try eventMatcher.removeSetOfMatchedEvents(triggeredEvents, for: campaign)
            dispatcher.addToQueue(campaign: campaign)
        } catch {
            // Campaign is not ready to be displayed
        }
    }
}
