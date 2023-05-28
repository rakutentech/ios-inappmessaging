import Foundation
import UIKit

#if SWIFT_PACKAGE
import RSDKUtilsMain
#else
import RSDKUtils
#endif

internal protocol TooltipDispatcherDelegate: AnyObject {
    func performPing()
    func shouldShowTooltip(title: String, contexts: [String]) -> Bool
}

internal protocol TooltipDispatcherType: AnyObject {
    var delegate: TooltipDispatcherDelegate? { get set }

    func setNeedsDisplay(tooltip: Campaign)
    func registerSwiftUITooltip(identifier: String, uiView: TooltipView)
    func refreshActiveTooltip(identifier: String, targetView: UIView?)
}

internal class TooltipDispatcher: TooltipDispatcherType, ViewListenerObserver {

    private let router: RouterType
    private let permissionService: DisplayPermissionServiceType
    private let campaignRepository: CampaignRepositoryType
    private let viewListener: ViewListenerType
    private let dispatchQueue = DispatchQueue(label: "IAM.TooltipDisplay", qos: .userInteractive)
    private(set) var httpSession: URLSession
    private(set) var activeTooltips = Set<Campaign>() // ensure to access only in dispatchQueue
    private var swiftUITooltips = [String: WeakWrapper<TooltipView>]()

    weak var delegate: TooltipDispatcherDelegate?

    init(router: RouterType,
         permissionService: DisplayPermissionServiceType,
         campaignRepository: CampaignRepositoryType,
         viewListener: ViewListenerType) {

        self.router = router
        self.permissionService = permissionService
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
        dispatchQueue.async { [weak self] in
            guard let self = self,
                  !self.activeTooltips.contains(tooltip) else {
                return
            }
            self.activeTooltips.insert(tooltip)
            self.findViewAndDisplay(tooltip: tooltip)
        }
    }

    func registerSwiftUITooltip(identifier: String, uiView: TooltipView) {
        swiftUITooltips[identifier] = WeakWrapper(value: uiView)
    }

    func refreshActiveTooltip(identifier: String, targetView: UIView?) {
        dispatchQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            for tooltip in self.activeTooltips {
                guard let uiElementIdentifier = tooltip.tooltipData?.bodyData.uiElementIdentifier,
                      identifier.contains(uiElementIdentifier) else {
                    continue
                }

                guard let tooltipView = self.swiftUITooltips[uiElementIdentifier]?.value else {
                    // UIKit
                    if let view = targetView {
                        self.displayTooltip(tooltip, targetView: view, identifier: uiElementIdentifier)
                    }
                    break
                }

                self.displaySwiftUITooltip(tooltip, tooltipView: tooltipView, identifier: uiElementIdentifier)
                break
            }
        }
    }

    private func findViewAndDisplay(tooltip: Campaign) {
        guard let tooltipData = tooltip.tooltipData else {
            return
        }
        let tooltipIdentifier = tooltipData.bodyData.uiElementIdentifier
        guard let tooltipView = swiftUITooltips[tooltipIdentifier]?.value else {
            // UIKit tooltip
            viewListener.iterateOverDisplayedViews { view, identifier, stop in
                if identifier.contains(tooltipIdentifier) {
                    stop = true
                    self.dispatchQueue.async {
                        self.displayTooltip(tooltip, targetView: view, identifier: identifier)
                    }
                }
            }
            return
        }
        displaySwiftUITooltip(tooltip, tooltipView: tooltipView, identifier: tooltipIdentifier)
    }

    private func prepareTooltipDisplay(_ tooltip: Campaign,
                                       identifier: String,
                                       success: @escaping (_ imageBlob: Data) -> Void) {
        guard !router.isDisplayingTooltip(with: identifier) else {
            return
        }
        guard let resImgUrlString = tooltip.tooltipData?.imageUrl,
              let resImgUrl = URL(string: resImgUrlString)
        else {
            return
        }

        let permissionResponse = permissionService.checkPermission(forCampaign: tooltip.data)
        if permissionResponse.performPing {
            delegate?.performPing()
        }

        guard permissionResponse.display || tooltip.data.isTest else {
            return
        }

        let waitForImageDispatchGroup = DispatchGroup()
        waitForImageDispatchGroup.enter()

        data(from: resImgUrl) { imageBlob in
            guard let imageBlob = imageBlob else {
                // TOOLTIP: add retry?
                return
            }
            success(imageBlob)
            waitForImageDispatchGroup.leave()
        }
    }

    private func displaySwiftUITooltip(_ tooltip: Campaign,
                                       tooltipView: TooltipView,
                                       identifier: String) {
        prepareTooltipDisplay(tooltip, identifier: identifier) { imageBlob in
            self.router.displaySwiftUITooltip(
                tooltip,
                tooltipView: tooltipView,
                identifier: identifier,
                imageBlob: imageBlob,
                confirmation: self.shouldCommitTooltipDisplay(tooltip),
                completion: { cancelled in
                    self.handleDisplayCompletion(cancelled: cancelled, tooltip: tooltip)
                }
            )
        }
    }

    private func displayTooltip(_ tooltip: Campaign,
                                targetView: UIView,
                                identifier: String) {
        prepareTooltipDisplay(tooltip, identifier: identifier) { imageBlob in
            self.router.displayTooltip(
                tooltip,
                targetView: targetView,
                identifier: identifier,
                imageBlob: imageBlob,
                becameVisibleHandler: { tooltipView in
                    tooltipView.presenter?.startAutoDisappearIfNeeded()
                },
                confirmation: self.shouldCommitTooltipDisplay(tooltip),
                completion: { cancelled in
                    self.handleDisplayCompletion(cancelled: cancelled, tooltip: tooltip)
                }
            )
        }
    }

    private func shouldCommitTooltipDisplay(_ tooltip: Campaign) -> Bool {
        let contexts = Array(tooltip.contexts.dropFirst()) // first context will always be "Tooltip"
        let tooltipTitle = tooltip.data.messagePayload.title
        guard let delegate = self.delegate, !contexts.isEmpty, !tooltip.data.isTest else {
            return true
        }
        let shouldShow = delegate.shouldShowTooltip(title: tooltipTitle,
                                                    contexts: contexts)
        return shouldShow
    }

    private func handleDisplayCompletion(cancelled: Bool, tooltip: Campaign) {
        dispatchQueue.async {
            if !cancelled {
                self.campaignRepository.decrementImpressionsLeftInCampaign(id: tooltip.id)
            }
            self.activeTooltips.remove(tooltip)
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

    func viewDidChangeSuperview(_ view: UIView, identifier: String) {
        guard view.superview != nil else {
            return
        }

        // refresh currently displayed tooltip or
        // restore tooltip if view appeared again
        refreshActiveTooltip(identifier: identifier, targetView: view)
    }

    func viewDidMoveToWindow(_ view: UIView, identifier: String) {
        viewDidChangeSuperview(view, identifier: identifier)
    }

    func viewDidGetRemovedFromSuperview(_ view: UIView, identifier: String) {
        // unused
    }

    func viewDidUpdateIdentifier(from: String?, to: String?, view: UIView) {
        if let newIdentifier = to {
            viewDidMoveToWindow(view, identifier: newIdentifier)
        }
    }
}
