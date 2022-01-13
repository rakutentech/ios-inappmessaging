import Foundation

protocol TooltipManagerType: AnyObject {

}

class TooltipManager: TooltipManagerType, ViewListenerObserver {

    private let viewListener: ViewListenerType
    private let campaignRepository: CampaignRepositoryType
    private var triggeredTooltipIds = [String]()

    init(viewListener: ViewListenerType,
         campaignRepository: CampaignRepositoryType) {

        self.viewListener = viewListener
        self.campaignRepository = campaignRepository
        viewListener.addObserver(self)
    }
}

// MARK: - ViewListenerObserver
extension TooltipManager {

    func viewDidChangeSubview(_ view: UIView, identifier: String) {
        guard view.superview != nil,
              let tooltip = campaignRepository.tooltipsList.first(where: {
                  guard let tooltipData = $0.tooltipData else {
                      return false
                  }
                  return identifier.contains(tooltipData.bodyData.uiElementIdentifier)
              })
        else { return }

        guard !triggeredTooltipIds.contains(tooltip.id) else {
            // only one tooltip display per app session
            return
        }

        triggeredTooltipIds.append(tooltip.id)
        RInAppMessaging.logEvent(ViewAppearedEvent(viewIdentifier: identifier))
    }

    func viewDidMoveToWindow(_ view: UIView, identifier: String) {
        viewDidChangeSubview(view, identifier: identifier)
    }

    func viewDidGetRemovedFromSuperview(_ view: UIView, identifier: String) { }

    func viewDidUpdateIdentifier(from: String?, to: String?, view: UIView) { }
}
