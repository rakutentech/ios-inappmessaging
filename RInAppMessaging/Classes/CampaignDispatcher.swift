import Foundation

internal protocol CampaignDispatcherDelegate: AnyObject {
    func performPing()
    func shouldShowCampaignMessage(title: String, contexts: [EventContext]) -> Bool
}

internal protocol CampaignDispatcherType {
    var delegate: CampaignDispatcherDelegate? { get set }

    func addToQueue(campaign: Campaign, contexts: [EventContext])
    func dispatchAllIfNeeded()
}

/// Class for adding ready (validated) campaigns to a queue to be sequentially displayed.
/// Each next campaign is scheduled after closing according to the Campaign's delay paramater.
internal class CampaignDispatcher: CampaignDispatcherType {

    private let router: RouterType
    private let permissionService: DisplayPermissionServiceType
    private let campaignRepository: CampaignRepositoryType

    private let dispatchQueue = DispatchQueue(label: "IAM.Campaign", attributes: .concurrent)
    private var queuedCampaigns = [(campaign: Campaign, contexts: [EventContext])]()
    private var isDispatching = false

    weak var delegate: CampaignDispatcherDelegate?

    init(router: RouterType,
         permissionService: DisplayPermissionServiceType,
         campaignRepository: CampaignRepositoryType) {

        self.router = router
        self.permissionService = permissionService
        self.campaignRepository = campaignRepository
    }

    func addToQueue(campaign: Campaign, contexts: [EventContext]) {
        dispatchQueue.async(flags: .barrier) {
            self.queuedCampaigns.append((campaign, contexts))
        }
    }

    func dispatchAllIfNeeded() {
        guard !isDispatching else {
            return
        }

        isDispatching = true
        dispatchNext()
    }

    private func dispatchNext() {

        dispatchQueue.async(flags: .barrier) {
            guard !self.queuedCampaigns.isEmpty else {
                self.isDispatching = false
                return
            }

            let queuedElement = self.queuedCampaigns.removeFirst()
            var campaign = queuedElement.campaign

            let permissionResponse = self.permissionService.checkPermission(forCampaign: campaign.data)
            if permissionResponse.performPing {
                self.delegate?.performPing()
            }
            guard campaign.data.isTest || permissionResponse.display else {
                self.dispatchNext()
                return
            }

            if let updatedCampaign = self.campaignRepository.decrementImpressionsLeftInCampaign(campaign) {
                campaign = updatedCampaign
            } else {
                CommonUtility.debugPrint("""
                    Error: Campaign (\(campaign.id)) does not exist in the repository anymore (race condition?). Proceeding with old data...
                    """)
            }

            let campaignTitle = campaign.data.messagePayload.title
            self.router.displayCampaign(campaign, confirmation: {
                guard let delegate = self.delegate, !campaign.data.isTest else {
                    return true
                }
                // validate contexts
                return delegate.shouldShowCampaignMessage(title: campaignTitle,
                                                          contexts: queuedElement.contexts)
            }, completion: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                WorkScheduler.scheduleTask(
                    milliseconds: strongSelf.delayBeforeNextMessage(for: campaign.data),
                    closure: strongSelf.dispatchNext)
            })
        }
    }

    private func delayBeforeNextMessage(for campaignData: CampaignData) -> Int {
        return campaignData.intervalBetweenDisplaysInMS ??
            Constants.CampaignMessage.defaultIntervalBetweenDisplaysInMS
    }
}
