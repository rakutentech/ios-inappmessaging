import UIKit

internal protocol RouterType: AnyObject {
    var accessibilityCompatibleDisplay: Bool { get set }

    /// Contains logic to display the correct view type and create
    /// a view controller to present a single campaign.
    /// - Parameter campaign: The campaign object to display.
    /// - Parameter confirmation: A handler called just before displaying.
    /// - Parameter completion: Completion handler called once displaying has finished.
    func displayCampaign(_ campaign: Campaign,
                         confirmation: @escaping @autoclosure () -> Bool,
                         completion: @escaping () -> Void)
}

/// Handles all the displaying logic of the SDK.
internal class Router: RouterType {

    private let dependencyManager: DependencyManager
    var accessibilityCompatibleDisplay = false

    init(dependencyManager: DependencyManager) {
        self.dependencyManager = dependencyManager
    }

    func displayCampaign(_ campaign: Campaign,
                         confirmation: @escaping @autoclosure () -> Bool,
                         completion: @escaping () -> Void) {

        guard let campaignViewType = campaign.data.type, campaignViewType != .invalid else {
            CommonUtility.debugPrint("Error: Campaign view type not supported")
            completion()
            return
        }

        DispatchQueue.global(qos: .userInteractive).async {

            func getPresenter<T>(type: T.Type) -> T? {
                guard let presenter = self.dependencyManager.resolve(type: type) else {
                    CommonUtility.debugPrint("Error: \(type) couldn't be resolved")
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
                CommonUtility.debugPrint("Error: Campaign view type not supported")
            }

            DispatchQueue.main.async {
                guard let view = viewConstructor?(), confirmation() == true else {
                    completion()
                    return
                }
                view.show(accessibilityCompatible: self.accessibilityCompatibleDisplay, onDismiss: {
                    completion()
                })
            }
        }
    }
}
