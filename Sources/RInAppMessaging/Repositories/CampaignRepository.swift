import Foundation

#if SWIFT_PACKAGE
import RSDKUtilsMain
#else
import RSDKUtils
#endif

internal protocol CampaignRepositoryType: AnyObject, Lockable {
    var list: [Campaign] { get }
    var tooltipsList: [Campaign] { get }
    var lastSyncInMilliseconds: Int64? { get }
    var delegate: CampaignRepositoryDelegate? { get set }

    /// Used to sync with list from the server. Server list is considered as source of truth.
    /// Order must be preserved.
    /// - Parameters
    ///     - list: a list of newly fetched campaigns.
    ///     - timestampMilliseconds: timestamp from last ping response.
    ///     - ignoreTooltips: set to `true` if Tooltip feature is disabled.
    func syncWith(list: [Campaign], timestampMilliseconds: Int64, ignoreTooltips: Bool)

    /// Opts out the campaign and updates the repository.
    /// - Parameter campaign: The campaign to opt out.
    /// - Returns: A new campaign structure with updated opt out status
    /// or `nil` if campaign couldn't be found in the repository.
    @discardableResult
    func optOutCampaign(_ campaign: Campaign) -> Campaign?

    /// Decrements number of impressionsLeft for provided campaign id in the repository.
    /// - Parameter id: The id of a campaign whose impressionsLeft value is to be updated.
    /// - Returns: An updated campaign model with updated impressionsLeft value
    /// or `nil` if campaign couldn't be found in the repository.
    @discardableResult
    func decrementImpressionsLeftInCampaign(id: String) -> Campaign?

    /// Increments number of impressionsLeft for provided campaign id in the repository.
    /// - Parameter id: The id of a campaign whose impressionsLeft value is to be updated.
    /// - Returns: An updated campaign model with updated impressionsLeft value
    /// or `nil` if campaign couldn't be found in the repository.
    @discardableResult
    func incrementImpressionsLeftInCampaign(id: String) -> Campaign?

    /// Loads cached campaign data of current user
    func loadCachedData()
}

internal protocol CampaignRepositoryDelegate: AnyObject {
    func didUpdateCampaignList()
}

/// Repository to store campaigns retrieved from ping request.
internal class CampaignRepository: CampaignRepositoryType {

    private let userDataCache: UserDataCacheable
    private let accountRepository: AccountRepositoryType
    private let allCampaigns = LockableObject([Campaign]())
    private let tooltips = LockableObject([Campaign]())
    private(set) var lastSyncInMilliseconds: Int64?

    weak var delegate: CampaignRepositoryDelegate?

    var list: [Campaign] {
        allCampaigns.get()
    }
    /// A subset of `list`
    var tooltipsList: [Campaign] {
        tooltips.get()
    }
    var resourcesToLock: [LockableResource] {
        [allCampaigns, tooltips]
    }

    init(userDataCache: UserDataCacheable, accountRepository: AccountRepositoryType) {
        self.userDataCache = userDataCache
        self.accountRepository = accountRepository

        loadCachedData()
    }

    func syncWith(list: [Campaign], timestampMilliseconds: Int64, ignoreTooltips: Bool) {
        print("IAM Debug: \(Date()) syncWith()")
        lastSyncInMilliseconds = timestampMilliseconds
        let oldList = allCampaigns.get()

        let retainImpressionsLeftValue = true // Left for feature flag functionality
        let updatedList: [Campaign] = list.map { newCampaign in
            var updatedCampaign = newCampaign
            if let oldCampaign = oldList.first(where: { $0.id == newCampaign.id }) {
                updatedCampaign = Campaign.updatedCampaign(updatedCampaign, asOptedOut: oldCampaign.isOptedOut)

                if retainImpressionsLeftValue {
                    var newImpressionsLeft = oldCampaign.impressionsLeft
                    let wasMaxImpressionsEdited = oldCampaign.data.maxImpressions != newCampaign.data.maxImpressions
                    if wasMaxImpressionsEdited {
                        newImpressionsLeft += newCampaign.data.maxImpressions - oldCampaign.data.maxImpressions
                    }
                    updatedCampaign = Campaign.updatedCampaign(updatedCampaign, withImpressionLeft: newImpressionsLeft)
                }
            }
            return updatedCampaign
        }
        if ignoreTooltips {
            allCampaigns.set(value: updatedList.filter({ !$0.isTooltip }))
        } else {
            allCampaigns.set(value: updatedList)
            tooltips.set(value: updatedList.filter({ $0.isTooltip }))
        }
        print("IAM Debug: \(Date()) updatedList \(updatedList)")
        saveDataToCache(updatedList)
        delegate?.didUpdateCampaignList()
    }

    @discardableResult
    func optOutCampaign(_ campaign: Campaign) -> Campaign? {
        var newList = allCampaigns.get()
        guard let index = newList.firstIndex(where: { $0.id == campaign.id }) else {
            Logger.debug("Campaign \(campaign.id) cannot be updated - not found in repository")
            return nil
        }

        let updatedCampaign = Campaign.updatedCampaign(campaign, asOptedOut: true)
        newList[index] = updatedCampaign
        allCampaigns.set(value: newList)

        if !campaign.data.isTest {
            saveDataToCache(newList)
        }

        return updatedCampaign
    }

    @discardableResult
    func decrementImpressionsLeftInCampaign(id: String) -> Campaign? {
        print("IAM Debug: \(Date()) decrementImpressionsLeftInCampaign()")
        return updateImpressionsLeftInCampaign(withID: id, by: -1)
    }

    @discardableResult
    func incrementImpressionsLeftInCampaign(id: String) -> Campaign? {
        updateImpressionsLeftInCampaign(withID: id, by: 1)
    }

    func loadCachedData() {
        print("IAM Debug: \(Date()) loadCachedData()")
        let cachedData = userDataCache.getUserData(identifiers: accountRepository.getUserIdentifiers())?.campaignData ?? []
        print("IAM Debug: \(Date()) cachedData \(cachedData)")
        allCampaigns.set(value: cachedData)
    }

    // MARK: - Helpers

    private func updateImpressionsLeftInCampaign(withID id: String, by value: Int) -> Campaign? {
        print("IAM Debug: \(Date()) updateImpressionsLeftInCampaign()")
        var newList = allCampaigns.get()
        guard let index = newList.firstIndex(where: { $0.id == id }) else {
            print("IAM Debug: \(Date()) Campaign \(id) could not be updated - not found in the repository")
            Logger.debug("Campaign \(id) could not be updated - not found in the repository")
            return nil
        }
        let campaign = newList[index]
        let updatedCampaign = Campaign.updatedCampaign(campaign, withImpressionLeft: max(0, campaign.impressionsLeft + value))
        newList[index] = updatedCampaign
        allCampaigns.set(value: newList)
        print("IAM Debug: \(Date()) newList : \(newList)")
        saveDataToCache(newList)
        return updatedCampaign
    }

    private func saveDataToCache(_ list: [Campaign]) {
        print("IAM Debug: \(Date()) saveDataToCache()")
        let user = accountRepository.getUserIdentifiers()
        userDataCache.cacheCampaignData(list, userIdentifiers: user)
    }
}
