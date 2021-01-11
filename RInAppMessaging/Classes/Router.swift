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
    func discardDisplayedCampaign()
}

/// Handles all the displaying logic of the SDK.
internal class Router: RouterType {

    private let dependencyManager: DependencyManager
    var accessibilityCompatibleDisplay = false

    init(dependencyManager: DependencyManager) {
        self.dependencyManager = dependencyManager
    }

    func discardDisplayedCampaign() {
        DispatchQueue.main.async {
            guard let rootView = UIApplication.shared.getKeyWindow() else {
                return
            }

            let presentedView = self.findPresentedIAMView(from: rootView)
            presentedView?.removeFromSuperview()
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

        DispatchQueue.global(qos: .userInteractive).async {

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
                guard let view = viewConstructor?(), confirmation() == true else {
                    completion(true)
                    return
                }
                guard let rootView = UIApplication.shared.getKeyWindow(),
                      self.findPresentedIAMView(from: rootView) == nil else {
                    return
                }

                var parentView: UIView = rootView

                // For accessibilityCompatible option, campaign view must be inserted to
                // UIWindow's main subview. Private instance of UITransitionView
                // shouldn't be used for that - that's why it's omitted.
                if self.accessibilityCompatibleDisplay,
                    let mainSubview = rootView.subviews.first(
                        where: { !$0.isKind(of: NSClassFromString("UITransitionView")!) }) {
                    parentView = mainSubview
                }

                view.show(accessibilityCompatible: self.accessibilityCompatibleDisplay,
                          parentView: parentView,
                          onDismiss: {
                    completion(false)
                })
            }
        }
    }

    private func findPresentedIAMView(from parentView: UIView) -> UIView? {
        for subview in parentView.subviews {
            let accessibilityIdentifier = subview.accessibilityIdentifier ?? ""
            if [FullScreenView.viewIdentifier,
                ModalView.viewIdentifier,
                SlideUpView.viewIdentifier].contains(accessibilityIdentifier) {
                return subview

            } else if let iamView = findPresentedIAMView(from: subview) {
                return iamView
            }
        }

        return nil
    }
}
