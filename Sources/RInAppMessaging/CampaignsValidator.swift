internal protocol CampaignsValidatorType {

    /// Cross references the list of campaigns from CampaignRepository
    /// and the list of matched events in EventMatcher to check
    /// if any campaigns are ready to be displayed.
    ///
    /// This method is called when:
    /// 1) MessageMixerService retrieves a new list from the ping endpoint.
    /// 2) Hostapp logs an event.
    /// 3) Campaign's button logs an event.
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
    private let triggerValidator = TriggerAttributesValidator.self

    init(campaignRepository: CampaignRepositoryType,
         eventMatcher: EventMatcherType) {

        self.campaignRepository = campaignRepository
        self.eventMatcher = eventMatcher
    }

    func validate(validatedCampaignHandler: (_ campaign: Campaign, _ events: Set<Event>) -> Void) {

        campaignRepository.list.forEach { campaign in
            guard campaign.impressionsLeft > 0 else {
                return
            }
            
            guard campaign.data.isTest || (!campaign.isOptedOut && !campaign.isOutdated) else {
                return
            }

            guard !(campaign.isPushPrimer && isNotificationsAllowed()) else {
                return
            }

            guard let campaignTriggers = campaign.data.triggers else {
                Logger.debug("campaign (\(campaign.id)) has no triggers.")
                return
            }

            let matchedEvents = eventMatcher.matchedEvents(for: campaign)
            guard eventMatcher.containsAllRequiredEvents(for: campaign),
                let triggeredEvents = triggerEvents(triggers: campaignTriggers,
                                                    loggedEvents: matchedEvents,
                                                    isTooltip: campaign.isTooltip) else {
                return
            }

            validatedCampaignHandler(campaign, triggeredEvents)
        }
    }

    /// Finds set of events that match all triggers
    /// - Returns: A set of events that satisfy all triggers
    /// or `nil` if even one trigger was not satisfied
    private func triggerEvents(triggers: [Trigger],
                               loggedEvents: [Event],
                               isTooltip: Bool) -> Set<Event>? {
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

        if isTooltip {
            // ViewAppearedEvent doesn't have its Trigger counterpart - it's an internal event.
            guard let viewAppearedEvent = loggedEvents.first(where: { $0 is ViewAppearedEvent }) else {
                return nil
            }

            triggeredEvents.insert(viewAppearedEvent)
        }

        return triggeredEvents
    }

    private func isNotificationsAllowed() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var authorizationStatus: UNAuthorizationStatus = .notDetermined

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            authorizationStatus = settings.authorizationStatus
            semaphore.signal()
        }
        semaphore.wait()

        return authorizationStatus == .authorized
    }
}
