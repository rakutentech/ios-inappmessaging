import Foundation
import UIKit

internal protocol TooltipDispatcherType {

}

internal class TooltipDispatcher: TooltipDispatcherType, TaskSchedulable, ViewListenerObserver {

    private let router: RouterType
    private let campaignRepository: CampaignRepositoryType

    private(set) var queuedCampaignIDs = [String]()
    private(set) var isDispatching = false

    weak var delegate: CampaignDispatcherDelegate?
    var scheduledTask: DispatchWorkItem?
    private(set) var httpSession: URLSession

    init(router: RouterType,
         campaignRepository: CampaignRepositoryType,
         viewListener: ViewListenerType) {

        self.router = router
        self.campaignRepository = campaignRepository

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

    private func displayTooltip(_ tooltip: Campaign,
                                targetView: UIView,
                                identifier: String,
                                imageBlob: Data) {
        guard tooltip.impressionsLeft > 0,
              let tooltipData = tooltip.tooltipData
        else {
            // TOOLTIP: dates? display premission?
            return
        }

        router.displayTooltip(
            tooltipData,
            targetView: targetView,
            identifier: identifier,
            imageBlob: imageBlob,
            becameVisibleHandler: { tooltipView in
                guard let autoFadeSeconds = tooltipData.autoFadeSeconds, autoFadeSeconds > 0 else {
                    return
                }
                tooltipView.startAutoFadingIfNeeded(seconds: autoFadeSeconds)
            }, completion: {
                self.campaignRepository.decrementImpressionsLeftInCampaign(id: tooltip.id)
            })
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
              let tooltip = campaignRepository.tooltipsList.first(where: {
                  guard let tooltipData = $0.tooltipData else {
                      return false
                  }
                  return identifier.contains(tooltipData.uiElementIdentifier)
              })
        else { return }

        guard let resImgUrlString = tooltip.data.messagePayload.resource.imageUrl,
              let resImgUrl = URL(string: resImgUrlString) else {
            assertionFailure()
            return
        }

        data(from: resImgUrl) { imgBlob in
            guard let imgBlob = imgBlob else {
                // TOOLTIP: add retry?
                return
            }
            self.displayTooltip(tooltip, targetView: view, identifier: identifier, imageBlob: imgBlob)
        }
    }

    func viewDidMoveToWindow(_ view: UIView, identifier: String) {
        viewDidChangeSubview(view, identifier: identifier)
    }

    func viewDidGetRemovedFromSuperview(_ view: UIView, identifier: String) { }

    func viewDidUpdateIdentifier(from: String?, to: String?, view: UIView) { }
}
