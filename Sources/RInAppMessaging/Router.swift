import UIKit
#if canImport(RSDKUtilsMain)
import RSDKUtilsMain // SPM version
#else
import RSDKUtils
#endif

internal protocol RouterType: AnyObject {
    var accessibilityCompatibleDisplay: Bool { get set }

    /// Contains logic to display the correct view type and create
    /// a view controller to present a single campaign.
    /// - Parameter campaign: The campaign object to display.
    /// - Parameter associatedImageData: Campaign-associated image as Data
    /// - Parameter confirmation: A handler called just before displaying.
    /// - Parameter completion: Completion handler called once displaying has finished.
    /// - Parameter cancelled: true when message display was cancelled
    func displayCampaign(_ campaign: Campaign,
                         associatedImageData: Data?,
                         confirmation: @escaping @autoclosure () -> Bool,
                         completion: @escaping (_ cancelled: Bool) -> Void)

    func displayTooltip(_ tooltipData: TooltipData,
                        targetView: UIView,
                        identifier: String,
                        imageBlob: Data,
                        becameVisibleHandler: @escaping (_ tooltipView: TooltipView) -> Void,
                        completion: @escaping () -> Void)

    /// Removes displayed campaign view from the stack
    func discardDisplayedCampaign()
}

/// Handles all the displaying logic of the SDK.
internal class Router: RouterType, ViewListenerObserver {

    private enum UIConstants {
        enum Tooltip {
            static let minDistFromEdge = 20.0
            static let targetViewSpacing = 0.0
        }
    }

    private let dependencyManager: TypedDependencyManager
    private let displayQueue = DispatchQueue(label: "IAM.MessageLoader")
    private var displayedTooltips = [String: TooltipView]()
    private var observers = [WeakWrapper<NSKeyValueObservation>]()

    var accessibilityCompatibleDisplay = false

    init(dependencyManager: TypedDependencyManager, viewListener: ViewListenerType) {
        self.dependencyManager = dependencyManager
        viewListener.addObserver(self)
    }

    func discardDisplayedCampaign() {
        displayQueue.sync {
            DispatchQueue.main.async {
                guard let rootView = UIApplication.shared.getKeyWindow(),
                      let presentedView = rootView.findIAMViewSubview() else {
                    return
                }

                presentedView.onDismiss?(true)
                presentedView.removeFromSuperview()
            }
        }
    }

    func displayCampaign(_ campaign: Campaign,
                         associatedImageData: Data?,
                         confirmation: @escaping @autoclosure () -> Bool,
                         completion: @escaping (_ cancelled: Bool) -> Void) {

        let campaignViewType = campaign.data.type
        guard campaignViewType != .invalid else {
            Logger.debug("Error: Campaign view type is invalid")
            completion(true)
            return
        }

        displayQueue.async {
            guard let viewConstructor = self.createViewConstructor(for: campaign, associatedImageData: associatedImageData) else {
                completion(true)
                return
            }

            DispatchQueue.main.async {
                guard let rootView = UIApplication.shared.getKeyWindow(),
                      rootView.findIAMViewSubview() == nil,
                      confirmation() else {

                    completion(true)
                    return
                }

                let view = viewConstructor()
                let parentView = self.findParentView(rootView: rootView)
                view.show(parentView: parentView, onDismiss: completion)
            }
        }
    }

    private func createViewConstructor(for campaign: Campaign, associatedImageData: Data?) -> (() -> BaseView)? {
        func getPresenter<T>(type: T.Type) -> T? {
            guard let presenter = self.dependencyManager.resolve(type: type) else {
                Logger.debug("Error: \(type) couldn't be resolved")
                return nil
            }
            return presenter
        }

        switch campaign.data.type {
        case .modal:
            guard let presenter = getPresenter(type: FullViewPresenterType.self) else {
                break
            }
            presenter.campaign = campaign
            if let associatedImageData = associatedImageData {
                presenter.associatedImage = UIImage(data: associatedImageData)
            }
            return { ModalView(presenter: presenter) }
        case .full:
            guard let presenter = getPresenter(type: FullViewPresenterType.self) else {
                break
            }
            presenter.campaign = campaign
            if let associatedImageData = associatedImageData {
                presenter.associatedImage = UIImage(data: associatedImageData)
            }
            return { FullScreenView(presenter: presenter) }
        case .slide:
            guard let presenter = getPresenter(type: SlideUpViewPresenterType.self) else {
                break
            }
            presenter.campaign = campaign
            return { SlideUpView(presenter: presenter) }
        case .invalid, .html:
            Logger.debug("Error: Campaign view type not supported")
        }

        return nil
    }

    func displayTooltip(_ tooltipData: TooltipData,
                        targetView: UIView,
                        identifier: String,
                        imageBlob: Data,
                        becameVisibleHandler: @escaping (_ tooltipView: TooltipView) -> Void,
                        completion: @escaping () -> Void) {

        DispatchQueue.main.async {
            self.displayedTooltips[identifier]?.removeFromSuperview()
            self.displayedTooltips[identifier] = nil

            let position = tooltipData.bodyData.position
            let tooltipView = TooltipView(
                model: TooltipViewModel(
                position: position,
                image: UIImage(data: imageBlob)!,
                backgroundColor: UIColor(hexString: tooltipData.backgroundColor) ?? .white))

            let onClose = {
                self.displayedTooltips[identifier]?.removeFromSuperview()
                self.displayedTooltips[identifier] = nil
                completion()
            }

            tooltipView.onImageTap = {
                if let uriToOpen = URL(string: tooltipData.bodyData.redirectURL ?? "") {
                    UIApplication.shared.open(uriToOpen)
                    onClose()
                }
            }
            tooltipView.onExitButtonTap = onClose

            let superview = self.findParentViewForTooltip(targetView)
            guard superview != targetView else {
                Logger.debug("Cannot find suitable view for tooltip targeting: \(targetView.description)")
                return
            }

            superview.addSubview(tooltipView)
            superview.layoutIfNeeded()
            if let displayedCampaign = superview.findIAMViewSubview() {
                superview.bringSubviewToFront(displayedCampaign)
            }

            self.updateFrame(targetView: targetView, tooltipView: tooltipView, superview: superview, position: position)

            if let parentScrollView = superview as? UIScrollView {
                let observer = parentScrollView.observe(\.contentOffset, options: [.new, .old]) { [weak self] layer, change in
                    self?.updateFrame(targetView: targetView, tooltipView: tooltipView, superview: superview, position: position)
                    if self?.isTooltipVisible(tooltipView) == true {
                        becameVisibleHandler(tooltipView)
                    }
                }
                self.observers.append(WeakWrapper(value: observer))
            } else {
                let observer = targetView.observe(\.frame, options: [.new, .old]) { [weak self] layer, change in
                    self?.updateFrame(targetView: targetView, tooltipView: tooltipView, superview: superview, position: position)
                    if self?.isTooltipVisible(tooltipView) == true {
                        becameVisibleHandler(tooltipView)
                    }
                }
                self.observers.append(WeakWrapper(value: observer))
            }

            // TOOLTIP: Keep tooltip away from sceen edges
    //        let distFromRightEdge = view.window!.bounds.maxX - tooltipView.frame.maxX
    //        if distFromRightEdge < UIConstants.minDistFromEdge {
    //            tooltipView.frame.origin.x -= UIConstants.minDistFromEdge - distFromRightEdge
    //        }
    //
    //        let distFromLeftEdge = UIConstants.minDistFromEdge - tooltipView.frame.minX
    //        if distFromLeftEdge < UIConstants.minDistFromEdge {
    //            tooltipView.frame.origin.x += distFromLeftEdge
    //        }

            self.displayedTooltips[identifier] = tooltipView
        }
    }

    private func findParentView(rootView: UIView) -> UIView {
        // For accessibilityCompatible option, campaign view must be inserted to
        // UIWindow's main subview. Private instance of UITransitionView
        // shouldn't be used for that - that's why it's omitted.
        if accessibilityCompatibleDisplay,
           let transitionViewClass = NSClassFromString("UITransitionView"),
           let mainSubview = rootView.subviews.first(where: { !$0.isKind(of: transitionViewClass) }) {

            return mainSubview
        } else {
            return rootView
        }
    }

    private func findParentViewForTooltip(_ sourceView: UIView) -> UIView {
        let superview = sourceView.superview

        if superview?.isKind(of: UIScrollView.self) == true {
            return superview!
        } else if superview?.isKind(of: UIWindow.self) == true {
            if accessibilityCompatibleDisplay,
               let transitionViewClass = NSClassFromString("UITransitionView"),
               let transitionView = superview?.subviews.first(where: { !$0.isKind(of: transitionViewClass) }) {

                return transitionView
            } else {
                return superview!
            }
        } else if let superview = superview {
            return findParentViewForTooltip(superview)
        } else {
            return sourceView
        }
    }

    private func isTooltipVisible(_ toolTip: TooltipView) -> Bool {
        guard let window = UIApplication.shared.getKeyWindow(),
            let tooltipSuperview = toolTip.superview else {
            return false
        }
        let frameInWindow = window.convert(toolTip.frame, from: tooltipSuperview)
        return window.bounds.contains(frameInWindow)
    }

    private func updateFrame(targetView: UIView, tooltipView: TooltipView, superview: UIView, position: TooltipBodyData.Position) {
        guard targetView.superview != nil else {
            return
        }
        let targetViewFrame = superview.convert(targetView.frame, from: targetView.superview)

        switch position {
        case .topCentre:
            tooltipView.frame.origin = CGPoint(x: targetViewFrame.midX - tooltipView.frame.width / 2.0,
                                               y: targetViewFrame.origin.y - tooltipView.frame.height - UIConstants.Tooltip.targetViewSpacing)
        case .topLeft:
            tooltipView.frame.origin = CGPoint(x: targetViewFrame.minX - tooltipView.frame.width,
                                               y: targetViewFrame.origin.y - tooltipView.frame.height - UIConstants.Tooltip.targetViewSpacing)
        case .topRight:
            tooltipView.frame.origin = CGPoint(x: targetViewFrame.maxX,
                                               y: targetViewFrame.origin.y - tooltipView.frame.height - UIConstants.Tooltip.targetViewSpacing)
        case .bottomLeft:
            tooltipView.frame.origin = CGPoint(x: targetViewFrame.minX - tooltipView.frame.width,
                                               y: targetViewFrame.maxY + UIConstants.Tooltip.targetViewSpacing)
        case .bottomRight:
            tooltipView.frame.origin = CGPoint(x: targetViewFrame.maxX,
                                               y: targetViewFrame.maxY + UIConstants.Tooltip.targetViewSpacing)
        case .bottomCentre:
            tooltipView.frame.origin = CGPoint(x: targetViewFrame.midX - tooltipView.frame.width / 2.0,
                                               y: targetViewFrame.maxY + UIConstants.Tooltip.targetViewSpacing)
        case .left:
            tooltipView.frame.origin = CGPoint(x: targetViewFrame.minX - tooltipView.frame.width - UIConstants.Tooltip.targetViewSpacing,
                                               y: targetViewFrame.midY - tooltipView.frame.height / 2.0)
        case .right:
            tooltipView.frame.origin = CGPoint(x: targetViewFrame.maxX + UIConstants.Tooltip.targetViewSpacing,
                                               y: targetViewFrame.midY - tooltipView.frame.height / 2.0)
        }
    }
}

// MARK: - ViewListenerObserver
extension Router {
    func viewDidChangeSubview(_ view: UIView, identifier: String) { }

    func viewDidMoveToWindow(_ view: UIView, identifier: String) { }

    func viewDidGetRemovedFromSuperview(_ view: UIView, identifier: String) {
        displayedTooltips[identifier]?.removeFromSuperview()
        displayedTooltips[identifier] = nil
    }

    func viewDidUpdateIdentifier(from: String?, to: String?, view: UIView) {
        if let oldIdentifier = from, displayedTooltips[oldIdentifier] != nil {
            if let newIdentifier = to {
                displayedTooltips[newIdentifier] = displayedTooltips[oldIdentifier]
            } else {
                viewDidGetRemovedFromSuperview(view, identifier: oldIdentifier)
            }
        } else if let newIdentifier = to {
            viewDidMoveToWindow(view, identifier: newIdentifier)
        }
    }
}
