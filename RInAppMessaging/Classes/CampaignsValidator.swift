internal protocol CampaignsValidatorType {

    /// Cross references the list of campaigns from CampaignRepository
    /// and the list of matched events in EventMatcher to check
    /// if any campaigns are ready to be displayed.
    ///
    /// This method is called when:
    /// 1) MessageMixerClient retrieves a new list from the ping endpoint.
    /// 2) Hostapp logs an event.
    /// - Parameter validatedCampaignHandler: Handler that will be called synchronously.
    /// for every campaign that has been validated successsfuly.
    /// - Parameter campaign: validated campaign
    /// - Parameter events: a set of logged events that were required for this campaign.
    func validate(validatedCampaignHandler: (_ campaign: Campaign, _ events: Set<Event>) -> Void)
}

/// Class to handle the logic of checking if a campaign is ready to be displayed.
internal struct CampaignsValidator: CampaignsValidatorType {
    private let campaignRepository: CampaignRepositoryType
    private let eventMatcher: EventMatcherType
    private let campaignParser = CampaignParser.self
    private let triggerValidator = TriggerAttributesValidator.self

    init(campaignRepository: CampaignRepositoryType,
         eventMatcher: EventMatcherType) {

        self.campaignRepository = campaignRepository
        self.eventMatcher = eventMatcher
    }

    func validate(validatedCampaignHandler: (_ campaign: Campaign, _ events: Set<Event>) -> Void) {

        for campaign in campaignRepository.list {
            guard !campaign.data.isTest else {
                validatedCampaignHandler(campaign, [])
                // test campaigns are always ready
                continue
            }

            guard campaign.impressionsLeft > 0,
                !campaign.isOptedOut,
                !campaign.isOutdated else {
                    // campaign is not ready
                    continue
            }

            guard let campaignTriggers = campaign.data.triggers else {
                CommonUtility.debugPrint("InAppMessaging: campaign (\(campaign.id)) has no triggers.")
                continue
            }

            guard let triggeredEvents = triggerEvents(triggers: campaignTriggers,
                                                      loggedEvents: eventMatcher.matchedEvents(for: campaign)) else {
                continue
            }

            validatedCampaignHandler(campaign, triggeredEvents)
        }
    }

    /// Finds set of events that match all triggers
    /// - Returns: A set of events that satisfy all triggers
    /// or `nil` if even one trigger was not satisfied
    private func triggerEvents(triggers: [Trigger], loggedEvents: [Event]) -> Set<Event>? {
        guard !loggedEvents.isEmpty else {
            return nil
        }

        var triggeredEvents = Set<Event>()

        for trigger in triggers {
            guard let event = loggedEvents.first(where: {
                return $0.name == trigger.matchingEventName &&
                    triggerValidator.isTriggerSatisfied(trigger, $0) // check attributes
            }) else {
                // No event found for this trigger
                return nil
            }

            triggeredEvents.insert(event)
        }

        return triggeredEvents
    }
}
