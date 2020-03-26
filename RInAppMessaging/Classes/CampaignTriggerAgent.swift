internal protocol CampaignTriggerAgentType {
    func trigger(campaign: Campaign, triggeredEvents: Set<Event>)
}

internal struct CampaignTriggerAgent: CampaignTriggerAgentType {

    private let eventMatcher: EventMatcherType
    private let dispatcher: ReadyCampaignDispatcherType

    init(eventMatcher: EventMatcherType,
         readyCampaignDispatcher: ReadyCampaignDispatcherType) {

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
