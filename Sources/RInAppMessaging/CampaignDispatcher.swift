import Foundation

internal protocol CampaignDispatcherDelegate: AnyObject {
    func performPing()
    func shouldShowCampaignMessage(title: String, contexts: [String]) -> Bool
}

internal protocol CampaignDispatcherType: AnyObject {
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
    
    private let urlCache: URLCache = {
        // response must be <= 5% of mem/disk cap in order to committed to cache
        let cache = URLCache(memoryCapacity: URLCache.shared.memoryCapacity,
                                   diskCapacity: 100 * 1024 * 1024,  // fits up to 5MB images
                                   diskPath: "RInAppMessaging")
        return cache
    }()

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
        sessionConfig.timeoutIntervalForRequest = Constants.CampaignMessage.imageRequestTimeoutSeconds
        sessionConfig.timeoutIntervalForResource = Constants.CampaignMessage.imageResourceTimeoutSeconds
        sessionConfig.waitsForConnectivity = true
        sessionConfig.urlCache = urlCache
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

        guard campaign.impressionsLeft > 0 && (permissionResponse.display || campaign.data.isTest) else {
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
                    if !(campaign.data.customJson?.carousel?.images?.isEmpty ?? true) {
                        if let carouselData = campaign.data.customJson?.carousel {
                            DispatchQueue.main.sync {
                                self.fetchImagesArray(from: carouselData) { images in
                                    self.displayCampaign(campaign, imageBlob: imgBlob, carouselImages: images)
                                }
                            }
                        }
                    } else {
                        self.displayCampaign(campaign, imageBlob: imgBlob)
                    }
                }
            }
        } else {
            // If no image expected, just display the message.
            displayCampaign(campaign)
        }
    }

    private func displayCampaign(_ campaign: Campaign, imageBlob: Data? = nil, carouselImages: [UIImage?]? = nil) {
        let campaignTitle = campaign.data.messagePayload.title
        router.displayCampaign(campaign, associatedImageData: imageBlob, carouselImages: carouselImages, confirmation: {
            let contexts = campaign.contexts
            guard let delegate = self.delegate, !contexts.isEmpty, !campaign.data.isTest else {
                return true
            }
            let shouldShow = delegate.shouldShowCampaignMessage(title: campaignTitle,
                                                                contexts: contexts)
            return shouldShow

        }(), completion: { cancelled in
            self.dispatchQueue.async {
                self.commitCampaignDisplay(campaign, cancelled: cancelled)
            }
        })
    }

    private func commitCampaignDisplay(_ campaign: Campaign, cancelled: Bool) {
        if !cancelled {
            campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
        }
        guard !queuedCampaignIDs.isEmpty else {
            isDispatching = false
            return
        }
        if cancelled {
            dispatchNext()
        } else {
            scheduleTask(milliseconds: delayBeforeNextMessage(for: campaign.data)) {
                self.dispatchQueue.async { self.dispatchNext() }
            }
        }
    }

    private func delayBeforeNextMessage(for campaignData: CampaignData) -> Int {
        campaignData.intervalBetweenDisplaysInMS
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

    func fetchImagesArray(from carousel: Carousel, completion: @escaping ([UIImage?]) -> Void) {
        guard let imageDetails = carousel.images else {
            completion([])
            return
        }

        let filteredDetails = imageDetails
            .sorted { $0.key < $1.key }
            .prefix(Constants.CampaignMessage.carouselThreshold)
            .map { $0 }

        var images: [UIImage?] = Array(repeating: nil, count: filteredDetails.count)

        for (index, detail) in filteredDetails.enumerated() {
            guard let urlString = detail.value.imgUrl else {
                images[index] = nil
                continue
            }
            fetchCarouselImage(for: urlString) { image in
                images[index] = image
            }
        }
        completion(images)
    }

    func fetchCarouselImage(for urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString),
              ["jpg", "jpeg", "png"].contains(url.pathExtension.lowercased()) else {
            completion(nil)
            return
        }

        let request = URLRequest(url: url)

        // Check cache
        if let cachedResponse = self.urlCache.cachedResponse(for: request),
           let cachedImage = UIImage(data: cachedResponse.data) {
            completion(cachedImage)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let response = response,
               error == nil,
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let image = UIImage(data: data) {
                let cachedData = CachedURLResponse(response: response, data: data)
                self.urlCache.storeCachedResponse(cachedData, for: request)
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
}
