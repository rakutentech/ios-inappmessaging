import Foundation

internal protocol CampaignDispatcherDelegate: AnyObject {
    func performPing()
    func shouldShowCampaignMessage(title: String, contexts: [String]) -> Bool
}

internal protocol CampaignDispatcherType {
    var delegate: CampaignDispatcherDelegate? { get set }

    func addToQueue(campaignID: String)
    func resetQueue()
    func dispatchAllIfNeeded()
}

/// Class for adding ready (validated) campaigns to a queue to be sequentially displayed.
/// Each next campaign is scheduled after closing according to the Campaign's delay paramater.
internal class CampaignDispatcher: CampaignDispatcherType, TaskSchedulable {

    private let router: RouterType
    private let permissionService: DisplayPermissionServiceType
    private let campaignRepository: CampaignRepositoryType

    private let dispatchQueue = DispatchQueue(label: "IAM.CampaignDisplay", qos: .userInteractive)
    private(set) var queuedCampaignIDs = [String]()
    private(set) var isDispatching = false

    weak var delegate: CampaignDispatcherDelegate?
    var scheduledTask: DispatchWorkItem?
    private(set) var httpSession: URLSession

    init(router: RouterType,
         permissionService: DisplayPermissionServiceType,
         campaignRepository: CampaignRepositoryType) {

        self.router = router
        self.permissionService = permissionService
        self.campaignRepository = campaignRepository

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = Constants.CampaignMessage.imageResourceRequestTimeoutSeconds
        sessionConfig.urlCache = URLCache(
            memoryCapacity: 512_000,
            diskCapacity: 8_000_000_000, // 100_000_000(5MB) * 4 images / 0.05 capacity
            diskPath: "IAM.CampaignDisplay") // non-iCloud cache path
        httpSession = URLSession(configuration: sessionConfig)
    }

    func addToQueue(campaignID: String) {
        dispatchQueue.async {
            self.queuedCampaignIDs.append(campaignID)
        }
    }

    func resetQueue() {
        dispatchQueue.async {
            let isDisplayingCampaign = self.scheduledTask == nil && self.isDispatching
            if !isDisplayingCampaign {
                self.isDispatching = false
                self.scheduledTask?.cancel()
            }

            self.queuedCampaignIDs.removeAll()
        }
    }

    func dispatchAllIfNeeded() {
        dispatchQueue.async {
            guard !self.isDispatching else {
                return
            }

            self.isDispatching = true
            self.dispatchNext()
        }
    }

    /// Must be executed on `dispatchQueue`
    private func dispatchNext() {

        guard !queuedCampaignIDs.isEmpty else {
            isDispatching = false
            return
        }

        let campaignID = queuedCampaignIDs.removeFirst()
        guard let campaign = campaignRepository.list.first(where: { $0.id == campaignID }) else {
            Logger.debug("Warning: Queued campaign \(campaignID) does not exist in the repository anymore")
            return
        }
        let permissionResponse = permissionService.checkPermission(forCampaign: campaign.data)
        if permissionResponse.performPing {
            delegate?.performPing()
        }

        guard campaign.data.isTest || (permissionResponse.display && campaign.impressionsLeft > 0) else {
            dispatchNext()
            return
        }

        // fetch from imageUrl, display if successful, skip on error
        if let resImgUrlString = campaign.data.messagePayload.resource.imageUrl, let resImgUrl = URL(string: resImgUrlString) {
            data(from: resImgUrl) { imgBlob in
                self.dispatchQueue.async {
                    guard let imgBlob = imgBlob else {
                        self.dispatchNext()
                        return
                    }
                    self.displayCampaign(campaign, imageBlob: imgBlob)
                }
            }
        } else {
            // If no image expected, just display the message.
            displayCampaign(campaign)
        }
    }

    private func displayCampaign(_ campaign: Campaign, imageBlob: Data? = nil) {
        campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
        let campaignTitle = campaign.data.messagePayload.title

        router.displayCampaign(campaign, associatedImageData: imageBlob, confirmation: {
            let contexts = campaign.contexts
            guard let delegate = delegate, !contexts.isEmpty, !campaign.data.isTest else {
                return true
            }
            let shouldShow = delegate.shouldShowCampaignMessage(title: campaignTitle,
                                                                contexts: contexts)
            return shouldShow

        }(), completion: { cancelled in
            self.dispatchQueue.async {
                if cancelled {
                    self.campaignRepository.incrementImpressionsLeftInCampaign(id: campaign.id)
                }
                guard !self.queuedCampaignIDs.isEmpty else {
                    self.isDispatching = false
                    return
                }
                if cancelled {
                    self.dispatchNext()
                } else {
                    self.scheduleTask(milliseconds: self.delayBeforeNextMessage(for: campaign.data)) {
                        self.dispatchQueue.async { self.dispatchNext() }
                    }
                }
            }
        })
    }

    private func delayBeforeNextMessage(for campaignData: CampaignData) -> Int {
        return campaignData.intervalBetweenDisplaysInMS ??
            Constants.CampaignMessage.defaultIntervalBetweenDisplaysInMS
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
