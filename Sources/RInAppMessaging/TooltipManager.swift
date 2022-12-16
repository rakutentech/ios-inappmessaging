import Foundation
import class UIKit.UIView

protocol TooltipManagerType: AnyObject { }

class TooltipManager: TooltipManagerType, ViewListenerObserver, CampaignRepositoryDelegate {

    private let viewListener: ViewListenerType
    private let campaignRepository: CampaignRepositoryType
    private var triggeredTooltipIds = [String]()

    init(viewListener: ViewListenerType,
         campaignRepository: CampaignRepositoryType) {

        self.viewListener = viewListener
        self.campaignRepository = campaignRepository
        self.campaignRepository.delegate = self
        viewListener.addObserver(self)
    }

    private func verify(view: UIView, identifier: String) {
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
}

// MARK: - CampaignRepositoryDelegate
extension TooltipManager {

    func didUpdateCampaignList() {
        viewListener.iterateOverDisplayedViews { view, identifier, _ in
            self.verify(view: view, identifier: identifier)
        }
    }
}

// MARK: - ViewListenerObserver
extension TooltipManager {

    func viewDidChangeSuperview(_ view: UIView, identifier: String) {
        verify(view: view, identifier: identifier)
    }

    func viewDidMoveToWindow(_ view: UIView, identifier: String) {
        verify(view: view, identifier: identifier)
    }

    func viewDidGetRemovedFromSuperview(_ view: UIView, identifier: String) {
        // unused
    }

    func viewDidUpdateIdentifier(from: String?, to: String?, view: UIView) {
        guard let identifier = to else {
            return
        }
        verify(view: view, identifier: identifier)
    }
}
