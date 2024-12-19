import UIKit

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
        fetchCampaignImagesAndDisplay(campaign: campaign)
    }
    
    func fetchCampaignImagesAndDisplay(campaign: Campaign) {
        if let carouselData = campaign.data.customJson?.carousel,
           !(carouselData.images?.isEmpty ?? true) {
            fetchImagesArray(from: carouselData) { images in
                guard let carouselData = carouselData.images else { return }
                let carouselHandler = self.createCarouselDataList(from: carouselData, using: images)
                self.displayCampaign(campaign, carouselData: carouselHandler)
            }
        } else {
            guard let resImgUrlString = campaign.data.messagePayload.resource.imageUrl,
                  let resImgUrl = URL(string: resImgUrlString) else {
                // If no image expected, just display the message.
                displayCampaign(campaign)
                return
            }
            fetchImage(from: resImgUrl, for: campaign)
        }
    }

    private func displayCampaign(_ campaign: Campaign, imageBlob: Data? = nil, carouselData: [CarouselData]? = nil) {
        let campaignTitle = campaign.data.messagePayload.title
        router.displayCampaign(campaign, associatedImageData: imageBlob, carouselData: carouselData, confirmation: {
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
}


extension CampaignDispatcher {
    func fetchImagesArray(from carousel: Carousel, completion: @escaping ([UIImage?]) -> Void) {
        guard let imageDetails = carousel.images else {
            completion([])
            return
        }

        let filteredDetails = imageDetails
            .sorted { $0.key < $1.key }
            .prefix(Constants.CampaignMessage.carouselThreshold)
            .map { $0 }

        let dispatchGroup = DispatchGroup()
        var images: [UIImage?] = Array(repeating: nil, count: filteredDetails.count)

        for (index, detail) in filteredDetails.enumerated() {
            guard let urlString = detail.value.imgUrl else {
                images[index] = nil
                continue
            }
            dispatchGroup.enter()
            fetchCarouselImage(for: urlString) { image in
                images[index] = image
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            completion(images)
        }
    }
    
    func fetchCarouselImage(for urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString),
              ["jpg", "jpeg", "png"].contains(url.pathExtension.lowercased()) else {
            completion(nil)
            return
        }

        if let cachedImage = loadImageFromCache(for: url) {
            completion(cachedImage)
            return
        }

        imageData(from: url) { data, response, error in
            if let data = data, let response = response, error == nil,
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let image = UIImage(data: data) {
                self.cacheImage(data: data, for: url, response: response)
                completion(image)
            } else {
                completion(nil)
            }
        }
    }

    func loadImageFromCache(for url: URL) -> UIImage? {
        let request = URLRequest(url: url)
        if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
            return UIImage(data: cachedResponse.data)
        }
        return nil
    }

    func cacheImage(data: Data, for url: URL, response: URLResponse) {
        guard let httpResponse = response as? HTTPURLResponse else {
          return
        }
        let cachedData = CachedURLResponse(response: httpResponse, data: data)
        URLCache.shared.storeCachedResponse(cachedData, for: URLRequest(url: url))
    }

    func imageData(from url: URL, completion: @escaping (Data? ,URLResponse?, Error?) -> Void) {

        var request = URLRequest(url: url)
        request.cachePolicy = .useProtocolCachePolicy

        if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
            completion(cachedResponse.data, cachedResponse.response, nil)
            return
        }

        httpSession.dataTask(with: request) { (data, response, error) in
            completion(data, response, error)
        }.resume()
    }

    func data(from url: URL, completion: @escaping (Data?) -> Void) {
        httpSession.dataTask(with: URLRequest(url: url)) { (data, _, error) in
            guard error == nil else {
                completion(nil)
                return
            }
            completion(data)
        }.resume()
    }

     func fetchImage(from url: URL, for campaign: Campaign) {
        data(from: url) { imgBlob in
            self.dispatchQueue.async {
                guard let imgBlob = imgBlob else {
                    self.dispatchNext()
                    return
                }
                self.displayCampaign(campaign, imageBlob: imgBlob)
            }
        }
    }

    func createCarouselDataList(from data: [String: ImageDetails], using images: [UIImage?]) -> [CarouselData] {
        let sortedKeys = Array(data.keys).sorted()
        let imageDataList: [CarouselData] = sortedKeys.prefix(images.count).enumerated().map { index, key in
            let image = images[index]
            let altText = data[key]?.altText
            let link = data[key]?.link
            
            return CarouselData(image: image, altText: altText, link: link)
        }

        return imageDataList
    }
}
