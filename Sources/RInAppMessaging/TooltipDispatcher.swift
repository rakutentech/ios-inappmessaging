import Foundation
import UIKit

internal protocol TooltipDispatcherType {
    func setNeedsDisplay(tooltip: Campaign)
}

internal class TooltipDispatcher: TooltipDispatcherType, ViewListenerObserver {

    private let router: RouterType
    private let campaignRepository: CampaignRepositoryType
    private let viewListener: ViewListenerType
    private let dispatchQueue = DispatchQueue(label: "IAM.TooltipDisplay", qos: .userInteractive)
    private(set) var httpSession: URLSession
    private(set) var queuedTooltips = Set<Campaign>()
    private(set) var displayedViews = [UIView]()

    init(router: RouterType,
         campaignRepository: CampaignRepositoryType,
         viewListener: ViewListenerType) {

        self.router = router
        self.campaignRepository = campaignRepository
        self.viewListener = viewListener

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = Constants.CampaignMessage.imageRequestTimeoutSeconds
        sessionConfig.timeoutIntervalForResource = Constants.CampaignMessage.imageResourceTimeoutSeconds
        sessionConfig.waitsForConnectivity = true
        sessionConfig.urlCache = URLCache(
            // response must be <= 5% of mem/disk cap in order to committed to cache
            memoryCapacity: URLCache.shared.memoryCapacity,
            diskCapacity: 100*1024*1024, // fits up to 5MB images
            diskPath: "RInAppMessaging")
        httpSession = URLSession(configuration: sessionConfig)

        viewListener.addObserver(self)
    }

    func setNeedsDisplay(tooltip: Campaign) {
        dispatchQueue.async {
            self.queuedTooltips.insert(tooltip)
            self.findViewAndDisplay(tooltip: tooltip)
        }
    }

    private func findViewAndDisplay(tooltip: Campaign) {
        guard let tooltipData = tooltip.tooltipData else {
            return
        }
        viewListener.iterateOverDisplayedViews { view, identifier, stop in
            if identifier.contains(tooltipData.bodyData.uiElementIdentifier) {
                stop = true
                self.displayTooltip(tooltip, targetView: view, identifier: identifier)
            }
        }
    }

    private func displayTooltip(_ tooltip: Campaign,
                                targetView: UIView,
                                identifier: String) {
        guard let tooltipData = tooltip.tooltipData,
              let resImgUrlString = tooltip.tooltipData?.imageUrl,
              let resImgUrl = URL(string: resImgUrlString)
        else {
            // TOOLTIP: display premission?
            return
        }

        data(from: resImgUrl) { imageBlob in
            guard let imageBlob = imageBlob else {
                // TOOLTIP: add retry?
                return
            }
            self.router.displayTooltip(
                tooltipData,
                targetView: targetView,
                identifier: identifier,
                imageBlob: imageBlob,
                becameVisibleHandler: { tooltipView in
                    guard let autoFadeSeconds = tooltipData.bodyData.autoFadeSeconds, autoFadeSeconds > 0 else {
                        return
                    }
                    tooltipView.startAutoFadingIfNeeded(seconds: autoFadeSeconds)
                }, completion: {
                    self.campaignRepository.decrementImpressionsLeftInCampaign(id: tooltip.id)
                    self.queuedTooltips.remove(tooltip)
                })
        }
    }

    private func data(from url: URL, completion: @escaping (Data?) -> Void) {
        httpSession.dataTask(with: URLRequest(url: url)) { (data, _, error) in
            guard error == nil else {
                completion(nil)
                return
            }
            completion(data)
        }.resume()
    }
}

// MARK: - ViewListenerObserver
extension TooltipDispatcher {

    func viewDidChangeSubview(_ view: UIView, identifier: String) {
        guard view.superview != nil,
              let tooltip = queuedTooltips.first(where: {
                  guard let tooltipData = $0.tooltipData else {
                      return false
                  }
                  return identifier.contains(tooltipData.bodyData.uiElementIdentifier)
              })
        else { return }

        // refresh currently displayed tooltip or
        // restore tooltip if view appeared again
        dispatchQueue.async {
            self.displayTooltip(tooltip, targetView: view, identifier: identifier)
        }
    }

    func viewDidMoveToWindow(_ view: UIView, identifier: String) {
        viewDidChangeSubview(view, identifier: identifier)
    }

    func viewDidGetRemovedFromSuperview(_ view: UIView, identifier: String) { }

    func viewDidUpdateIdentifier(from: String?, to: String?, view: UIView) { }
}
