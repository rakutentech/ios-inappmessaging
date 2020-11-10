import Foundation

internal protocol CampaignDispatcherDelegate: AnyObject {
    func performPing()
    func shouldShowCampaignMessage(title: String, contexts: [String]) -> Bool
}

internal protocol CampaignDispatcherType {
    var delegate: CampaignDispatcherDelegate? { get set }

    func addToQueue(campaign: Campaign)
    func dispatchAllIfNeeded()
}

/// Class for adding ready (validated) campaigns to a queue to be sequentially displayed.
/// Each next campaign is scheduled after closing according to the Campaign's delay paramater.
internal class CampaignDispatcher: CampaignDispatcherType {

    private let router: RouterType
    private let permissionService: DisplayPermissionServiceType
    private let campaignRepository: CampaignRepositoryType

    private let dispatchQueue = DispatchQueue(label: "IAM.Campaign", attributes: .concurrent)
    private var queuedCampaigns = [Campaign]()
    private(set) var isDispatching = false

    weak var delegate: CampaignDispatcherDelegate?

    init(router: RouterType,
         permissionService: DisplayPermissionServiceType,
         campaignRepository: CampaignRepositoryType) {

        self.router = router
        self.permissionService = permissionService
        self.campaignRepository = campaignRepository
    }

    func addToQueue(campaign: Campaign) {
        dispatchQueue.async(flags: .barrier) {
            self.queuedCampaigns.append(campaign)
        }
    }

    func dispatchAllIfNeeded() {

        dispatchQueue.async(flags: .barrier) {
            guard !self.isDispatching else {
                return
            }

            self.isDispatching = true
            self.dispatchNext()
        }
    }

    private func dispatchNext() {

        dispatchQueue.async(flags: .barrier) {
            guard !self.queuedCampaigns.isEmpty else {
                self.isDispatching = false
                return
            }

            let campaign = self.queuedCampaigns.removeFirst()
            let permissionResponse = self.permissionService.checkPermission(forCampaign: campaign.data)
            if permissionResponse.performPing {
                self.delegate?.performPing()
            }

            guard campaign.data.isTest || permissionResponse.display else {
                self.dispatchNext()
                return
            }

            let campaignTitle = campaign.data.messagePayload.title
            self.router.displayCampaign(campaign, confirmation: {
                let contexts = campaign.contexts
                guard let delegate = self.delegate, !contexts.isEmpty, !campaign.data.isTest else {
                    self.campaignRepository.decrementImpressionsLeftInCampaign(campaign)
                    return true
                }
                let shouldShow = delegate.shouldShowCampaignMessage(title: campaignTitle,
                                                                    contexts: contexts)
                if shouldShow {
                    self.campaignRepository.decrementImpressionsLeftInCampaign(campaign)
                }
                return shouldShow

            }(), completion: { cancelled in
                self.dispatchQueue.async(flags: .barrier) {

                    guard !self.queuedCampaigns.isEmpty else {
                        self.isDispatching = false
                        return
                    }
                    if cancelled {
                        self.dispatchNext()
                    } else {
                        WorkScheduler.scheduleTask(
                            milliseconds: self.delayBeforeNextMessage(for: campaign.data),
                            closure: self.dispatchNext
                        )
                    }
                }
            })
        }
    }

    private func delayBeforeNextMessage(for campaignData: CampaignData) -> Int {
        return campaignData.intervalBetweenDisplaysInMS ??
            Constants.CampaignMessage.defaultIntervalBetweenDisplaysInMS
    }
}
