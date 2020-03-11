import Foundation

internal protocol EventMatcherType: AnyObject {

    /// Function to store logged event.
    /// Event won't be stored if it is not categorized as global event
    /// or there are no campaigns with matching triggers.
    /// - Parameter event: An event to store
    func matchAndStore(event: Event)
    func matchedEvents(for campaign: Campaign) -> [Event]
    func containsAllMatchedEvents(for campaign: Campaign) -> Bool

    /// Function tries to find and remove one record for each event in set for provided campaign.
    /// Operation succeeds only if there is at least one record of each event.
    /// Function can be used with global events - they won't be removed.
    /// - Throws: Can throw EventMatcherError when records of requested events cannot be found
    func removeSetOfMatchedEvents(_ eventsToRemove: Set<Event>, for campaign: Campaign) throws
}

internal enum EventMatcherError: Error {
    case couldntFindRequestedSetOfEvents
}

/// A class to store logged events that match a campaign's trigger.
/// Campaigns are taken from provided `CampaignRepositoryType`
internal class EventMatcher: EventMatcherType {

    private let campaignRepository: CampaignRepositoryType
    private var matchedEvents = [String: [Event]]()
    private var globalEvents = Set<Event>()

    init(campaignRepository: CampaignRepositoryType) {
        self.campaignRepository = campaignRepository
    }

    func matchAndStore(event: Event) {
        guard !event.isGlobal else {
            globalEvents.insert(event)
            return
        }

        campaignRepository.list.forEach { campaign in
            guard let campaignTriggers = campaign.data.triggers else {
                CommonUtility.debugPrint("InAppMessaging: campaign (\(campaign.id)) has no triggers.")
                return
            }

            if isEventMatchingOneOfTriggers(event: event, triggers: campaignTriggers) {
                var campaignLoggedEvents = matchedEvents[campaign.id, default: []]
                campaignLoggedEvents.append(event)
                matchedEvents[campaign.id] = campaignLoggedEvents
                return
            }
        }
    }

    func matchedEvents(for campaign: Campaign) -> [Event] {
        return matchedEvents[campaign.id, default: []] + globalEvents
    }

    func containsAllMatchedEvents(for campaign: Campaign) -> Bool {
        guard let triggers = campaign.data.triggers else {
            return false
        }
        let events = matchedEvents[campaign.id, default: []] + globalEvents
        return events.allSatisfy { isEventMatchingOneOfTriggers(event: $0, triggers: triggers) }
    }

    func removeSetOfMatchedEvents(_ eventsToRemove: Set<Event>, for campaign: Campaign) throws {
        var campaignEvents = matchedEvents[campaign.id, default: []]
        guard campaignEvents.count + globalEvents.count >= eventsToRemove.count else {
            throw EventMatcherError.couldntFindRequestedSetOfEvents
        }

        for eventToRemove in eventsToRemove {
            guard let index = campaignEvents.firstIndex(of: eventToRemove) else {
                if eventToRemove.isGlobal && globalEvents.contains(eventToRemove) {
                    continue
                }
                throw EventMatcherError.couldntFindRequestedSetOfEvents
            }
            campaignEvents.remove(at: index)
        }

        matchedEvents[campaign.id] = campaignEvents
    }

    private func isEventMatchingOneOfTriggers(event: Event, triggers: [Trigger]) -> Bool {
        return triggers.first { trigger -> Bool in
            event.name == trigger.matchingEventName
        } != nil
    }

    private func isTriggerMatchingOneOfEvents(trigger: Trigger, events: [Event]) -> Bool {
        return events.first { event -> Bool in
            event.name == trigger.matchingEventName
        } != nil
    }
}

private extension Event {
    var isGlobal: Bool {
        return type == .appStart
    }
}

extension Trigger {
    var matchingEventName: String {
        // If event is a custom event, search by the name provided by the host app.
        // If event is a pre-defined event, search by using the enum name.
        return eventType == .custom ? eventName : eventType.name
    }
}
