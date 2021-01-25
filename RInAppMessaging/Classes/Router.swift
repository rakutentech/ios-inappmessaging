import UIKit

internal protocol RouterType: AnyObject {
    var accessibilityCompatibleDisplay: Bool { get set }

    /// Contains logic to display the correct view type and create
    /// a view controller to present a single campaign.
    /// - Parameter campaign: The campaign object to display.
    /// - Parameter confirmation: A handler called just before displaying.
    /// - Parameter completion: Completion handler called once displaying has finished.
    /// - Parameter cancelled: true when message display was cancelled
    func displayCampaign(_ campaign: Campaign,
                         confirmation: @escaping @autoclosure () -> Bool,
                         completion: @escaping (_ cancelled: Bool) -> Void)

    /// Removes displayed campaign view from the stack
    /// - Returns: a campaign associated with displayed message or nil if no message was displayed
    func discardDisplayedCampaign() -> Campaign?
}

/// Handles all the displaying logic of the SDK.
internal class Router: RouterType {

    private let dependencyManager: DependencyManager
    private let displayQueue = DispatchQueue(label: "IAM.MessageLoader")
    var accessibilityCompatibleDisplay = false

    init(dependencyManager: DependencyManager) {
        self.dependencyManager = dependencyManager
    }

    func discardDisplayedCampaign() -> Campaign? {
        return displayQueue.sync {
            let discard: () -> Campaign? = {
                guard let rootView = UIApplication.shared.getKeyWindow() else {
                    return nil
                }

                let presentedView = rootView.findIAMViewSubview()
                presentedView?.onDismiss?(true)
                presentedView?.removeFromSuperview()

                return presentedView?.basePresenter.campaign
            }

            return Thread.isMainThread ? discard() : DispatchQueue.main.sync(execute: discard)
        }
    }

    func displayCampaign(_ campaign: Campaign,
                         confirmation: @escaping @autoclosure () -> Bool,
                         completion: @escaping (_ cancelled: Bool) -> Void) {

        guard let campaignViewType = campaign.data.type, campaignViewType != .invalid else {
            Logger.debug("Error: Campaign view type not supported")
            completion(true)
            return
        }

        displayQueue.async {

            func getPresenter<T>(type: T.Type) -> T? {
                guard let presenter = self.dependencyManager.resolve(type: type) else {
                    Logger.debug("Error: \(type) couldn't be resolved")
                    return nil
                }
                return presenter
            }

            var viewConstructor: (() -> BaseView)?
            switch campaignViewType {
            case .modal:
                guard let presenter = getPresenter(type: FullViewPresenterType.self) else {
                    break
                }
                presenter.campaign = campaign
                presenter.loadResources()
                viewConstructor = { ModalView(presenter: presenter) }
            case .full:
                guard let presenter = getPresenter(type: FullViewPresenterType.self) else {
                    break
                }
                presenter.campaign = campaign
                presenter.loadResources()
                viewConstructor = { FullScreenView(presenter: presenter) }
            case .slide:
                guard let presenter = getPresenter(type: SlideUpViewPresenterType.self) else {
                    break
                }
                presenter.campaign = campaign
                viewConstructor = { SlideUpView(presenter: presenter) }
            case .invalid, .html:
                Logger.debug("Error: Campaign view type not supported")
            }

            DispatchQueue.main.async {
                guard let view = viewConstructor?(),
                      let rootView = UIApplication.shared.getKeyWindow(),
                      rootView.findIAMViewSubview() == nil,
                      confirmation() == true else {

                    completion(true)
                    return
                }

                let parentView = self.findParentView(rootView: rootView)
                view.show(accessibilityCompatible: self.accessibilityCompatibleDisplay,
                          parentView: parentView,
                          onDismiss: { cancelled in
                    completion(cancelled)
                })
            }
        }
    }

    private func findParentView(rootView: UIView) -> UIView {
        // For accessibilityCompatible option, campaign view must be inserted to
        // UIWindow's main subview. Private instance of UITransitionView
        // shouldn't be used for that - that's why it's omitted.
        if self.accessibilityCompatibleDisplay,
           let transitionViewClass = NSClassFromString("UITransitionView"),
           let mainSubview = rootView.subviews.first(where: { !$0.isKind(of: transitionViewClass) }) {

            return mainSubview
        } else {
            return rootView
        }
    }
}
