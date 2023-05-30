import Foundation

/// A special event for internal handling of Tooltip display cycle
internal class ViewAppearedEvent: Event {

    internal let viewIdentifier: String

    init(viewIdentifier: String) {
        self.viewIdentifier = viewIdentifier
        super.init(type: EventType.viewAppeared,
                   name: Constants.Event.viewAppeared)
    }
}
