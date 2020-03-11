private enum TriggerError: Error {
    case campaignTriggersNotSatisfied
    case eventMatchingError(_ error: EventMatcherError)
}

/// Provides default handling for validated campaigns that are meant to be displayed
internal struct CampaignsValidatorHelper {

    static func defaultValidatedCampaignHandler(eventMatcher: EventMatcherType,
                                                dispatcher: ReadyCampaignDispatcherType) -> (Campaign, Set<Event>) -> Void {
        return { campaign, triggeredEvents in
            do {
                try eventMatcher.removeSetOfMatchedEvents(triggeredEvents, for: campaign)
            } catch {
                // Campaign is not ready to be displayed
            }
            dispatcher.addToQueue(campaign: campaign)
        }
    }
}
