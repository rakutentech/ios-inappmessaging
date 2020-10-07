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
        CommonUtility.lock(resourcesIn: [eventMatcher]) {
            do {
                try eventMatcher.removeSetOfMatchedEvents(triggeredEvents, for: campaign)
                dispatcher.addToQueue(campaign: campaign,
                                      contexts: triggeredEvents.compactMap({ $0.context }))
            } catch {
                // Campaign is not ready to be displayed
            }
        }
    }
}
