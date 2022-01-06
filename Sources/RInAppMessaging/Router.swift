import UIKit
#if canImport(RSDKUtilsMain)
import class RSDKUtilsMain.TypedDependencyManager // SPM version
#else
import class RSDKUtils.TypedDependencyManager
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

    /// Removes displayed campaign view from the stack
    func discardDisplayedCampaign()
}

/// Handles all the displaying logic of the SDK.
internal class Router: RouterType {

    private let dependencyManager: TypedDependencyManager
    private let displayQueue = DispatchQueue(label: "IAM.MessageLoader")
    var accessibilityCompatibleDisplay = false

    init(dependencyManager: TypedDependencyManager) {
        self.dependencyManager = dependencyManager
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
                view.show(parentView: parentView,
                          onDismiss: { cancelled in
                    completion(cancelled)
                })
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
