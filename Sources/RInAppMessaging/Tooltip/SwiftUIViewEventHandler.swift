import Foundation
import UIKit

internal protocol SwiftUIViewEventHandlerType: AnyObject {
    func didAppear(identifier: String)
    func didDisappear(identifier: String)
    func didCreateTooltipView(_ tooltipView: TooltipView, identifier: String)
}

// This class handles SwiftUI tooltip target view events.
internal final class SwiftUIViewEventHandler: SwiftUIViewEventHandlerType {

    private let router: RouterType
    private let dispatcher: TooltipDispatcherType
    private let eventSender: TooltipEventSenderType

    init(router: RouterType,
         dispatcher: TooltipDispatcherType,
         eventSender: TooltipEventSenderType) {
        self.router = router
        self.dispatcher = dispatcher
        self.eventSender = eventSender
    }

    func didCreateTooltipView(_ tooltipView: TooltipView, identifier: String) {
        dispatcher.registerSwiftUITooltip(identifier: identifier, uiView: tooltipView)
    }

    func didAppear(identifier: String) {
        dispatcher.refreshActiveTooltip(identifier: identifier, targetView: nil) // restore undismissed tooltip
        eventSender.verifySwiftUIViewAppearance(identifier: identifier)
    }

    func didDisappear(identifier: String) {
        router.hideDisplayedTooltip(with: identifier)
    }
}
