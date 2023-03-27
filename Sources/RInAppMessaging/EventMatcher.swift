import Foundation

#if SWIFT_PACKAGE
import RSDKUtilsMain
#else
import RSDKUtils
#endif

internal protocol EventMatcherType: AnyObject, Lockable {

    /// Function to store logged event.
    /// Event won't be stored if it is not categorized as persistent event
    /// or there are no campaigns with matching triggers.
    /// - Parameter event: An event to store
    func matchAndStore(event: Event)
    func matchedEvents(for campaign: Campaign) -> [Event]
    func containsAllMatchedEvents(for campaign: Campaign) -> Bool

    /// Function tries to find and remove one record for each event in set for provided campaign.
    /// Operation succeeds only if there is at least one record of each event.
    /// Function can be used with persistent events - they won't be removed.
    /// - Throws: Can throw EventMatcherError when records of requested events cannot be found
    func removeSetOfMatchedEvents(_ eventsToRemove: Set<Event>, for campaign: Campaign) throws

    func clearNonPersistentEvents()
}

internal enum EventMatcherError: Error {
    case couldntFindRequestedSetOfEvents
    case providedSetOfEventsHaveAlreadyBeenUsed
}

/// A class to store logged events that match a campaign's trigger.
/// Campaigns are taken from provided `CampaignRepositoryType`
internal class EventMatcher: EventMatcherType {

    private let campaignRepository: CampaignRepositoryType
    private var matchedEvents = LockableObject([String: [Event]]())
    private var triggeredPersistentEventOnlyCampaigns = Set<String>()
    private var persistentEvents = Set<Event>()
    var resourcesToLock: [LockableResource] {
        [matchedEvents]
    }

    init(campaignRepository: CampaignRepositoryType) {
        self.campaignRepository = campaignRepository
    }

    func matchAndStore(event: Event) {
        guard !event.isPersistent else {
            persistentEvents.insert(event)
            return
        }

        campaignRepository.list.forEach { campaign in
            guard let campaignTriggers = campaign.data.triggers else {
                return
            }
            guard isEventMatchingOneOfTriggers(event, triggers: campaignTriggers) ||
                isEventMatchingTooltipData(event, tooltip: campaign) else {
                return
            }

            var events = matchedEvents.get()
            var campaignLoggedEvents = events[campaign.id, default: []]
            campaignLoggedEvents.append(event)
            events[campaign.id] = campaignLoggedEvents
            matchedEvents.set(value: events)
        }
    }

    func matchedEvents(for campaign: Campaign) -> [Event] {
        matchedEvents.get()[campaign.id, default: []] + persistentEvents
    }

    func containsAllMatchedEvents(for campaign: Campaign) -> Bool {
        guard let triggers = campaign.data.triggers, !triggers.isEmpty else {
            return false
        }
        let events = matchedEvents.get()[campaign.id, default: []] + persistentEvents
        let allTriggersSatisfied = triggers.allSatisfy { isTriggerMatchingOneOfEvents($0, events: events) }
        
        guard campaign.isTooltip else {
            return allTriggersSatisfied
        }
        return allTriggersSatisfied && events.contains(where: { $0.type == .viewAppeared })
    }

    func removeSetOfMatchedEvents(_ eventsToRemove: Set<Event>, for campaign: Campaign) throws {
        var campaignEvents = matchedEvents.get()[campaign.id, default: []]
        let totalMatchedEvents = campaignEvents.count + persistentEvents.count
        guard totalMatchedEvents > 0, totalMatchedEvents >= eventsToRemove.count else {
            throw EventMatcherError.couldntFindRequestedSetOfEvents
        }

        let persistentEventsOnlyCampaign = campaignEvents.isEmpty
        guard !(persistentEventsOnlyCampaign && triggeredPersistentEventOnlyCampaigns.contains(campaign.id)) else {
            throw EventMatcherError.providedSetOfEventsHaveAlreadyBeenUsed
        }

        for eventToRemove in eventsToRemove {
            guard let index = campaignEvents.firstIndex(of: eventToRemove) else {
                if eventToRemove.isPersistent && persistentEvents.contains(eventToRemove) {
                    continue
                }
                throw EventMatcherError.couldntFindRequestedSetOfEvents
            }
            campaignEvents.remove(at: index)
        }

        if persistentEventsOnlyCampaign {
            triggeredPersistentEventOnlyCampaigns.insert(campaign.id)
        } else {
            var events = matchedEvents.get()
            events[campaign.id] = campaignEvents
            matchedEvents.set(value: events)
        }
    }

    func clearNonPersistentEvents() {
        matchedEvents.set(value: [:])
    }

    private func isEventMatchingOneOfTriggers(_ event: Event, triggers: [Trigger]) -> Bool {
        triggers.contains { trigger -> Bool in
            event.name == trigger.matchingEventName
        }
    }

    private func isTriggerMatchingOneOfEvents(_ trigger: Trigger, events: [Event]) -> Bool {
        events.contains { event -> Bool in
            event.name == trigger.matchingEventName
        }
    }

    private func isEventMatchingTooltipData(_ event: Event, tooltip: Campaign) -> Bool {
        guard let viewEvent = event as? ViewAppearedEvent,
              tooltip.isTooltip,
              let tooltipData = tooltip.tooltipData
        else {
            return false
        }

        return viewEvent.viewIdentifier.contains(tooltipData.bodyData.uiElementIdentifier)
    }
}

private extension Event {
    var isPersistent: Bool {
        type == .appStart
    }
}

extension Trigger {
    var matchingEventName: String {
        // If event is a custom event, search by the name provided by the host app.
        // If event is a pre-defined event, search by using the enum name.
        eventType == .custom ? eventName.lowercased() : eventType.name
    }
}
