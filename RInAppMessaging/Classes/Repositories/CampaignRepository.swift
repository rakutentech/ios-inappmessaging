internal protocol CampaignRepositoryType: AnyObject, Lockable {
    var list: [Campaign] { get }
    var lastSyncInMilliseconds: Int64? { get }

    /// Used to sync with list from the server. Server list is considered as source of truth.
    /// Order must be preserved.
    func syncWith(list: [Campaign], timestampMilliseconds: Int64)

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

    /// Loads campaign data from user cache
    func loadCachedData()
}

/// Repository to store campaigns retrieved from ping request.
internal class CampaignRepository: CampaignRepositoryType {

    private let userDataCache: UserDataCacheable
    private let preferenceRepository: IAMPreferenceRepository
    private let campaigns = LockableObject([Campaign]())
    private(set) var lastSyncInMilliseconds: Int64?
    var list: [Campaign] {
        return campaigns.get()
    }
    var resourcesToLock: [LockableResource] {
        return [campaigns]
    }

    init(userDataCache: UserDataCacheable, preferenceRepository: IAMPreferenceRepository) {
        self.userDataCache = userDataCache
        self.preferenceRepository = preferenceRepository

        loadCachedData()
    }

    func syncWith(list: [Campaign], timestampMilliseconds: Int64) {
        lastSyncInMilliseconds = timestampMilliseconds
        let oldList = self.campaigns.get()
        var newList = [Campaign]()

        let retainImpressionsLeftValue = true // Left for feature flag functionality
        list.forEach { newCampaign in
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
            newList.append(updatedCampaign)
        }
        self.campaigns.set(value: newList)
        userDataCache.cacheCampaignData(newList, userIdentifiers: preferenceRepository.getUserIdentifiers())
    }

    @discardableResult
    func optOutCampaign(_ campaign: Campaign) -> Campaign? {
        var list = self.campaigns.get()
        guard let index = list.firstIndex(where: { $0.id == campaign.id }) else {
            Logger.debug("Campaign \(campaign.id) cannot be updated - not found in repository")
            return nil
        }

        let updatedCampaign = Campaign.updatedCampaign(campaign, asOptedOut: true)
        list[index] = updatedCampaign
        self.campaigns.set(value: list)
        userDataCache.cacheCampaignData(list, userIdentifiers: preferenceRepository.getUserIdentifiers())
        return updatedCampaign
    }

    @discardableResult
    func decrementImpressionsLeftInCampaign(id: String) -> Campaign? {
        guard let campaign = findCampaign(withID: id) else {
            return nil
        }
        return updateImpressionsLeftInCampaign(campaign, newValue: max(0, campaign.impressionsLeft - 1))
    }

    @discardableResult
    func incrementImpressionsLeftInCampaign(id: String) -> Campaign? {
        guard let campaign = findCampaign(withID: id) else {
            return nil
        }
        return updateImpressionsLeftInCampaign(campaign, newValue: campaign.impressionsLeft + 1)
    }

    func loadCachedData() {
        let cachedData = userDataCache.getUserData(identifiers: preferenceRepository.getUserIdentifiers())?.campaignData
        campaigns.set(value: cachedData ?? [])
    }

    private func findCampaign(withID id: String) -> Campaign? {
        campaigns.get().first(where: { $0.id == id })
    }

    private func updateImpressionsLeftInCampaign(_ campaign: Campaign, newValue: Int) -> Campaign? {
        var list = campaigns.get()
        guard let index = list.firstIndex(where: { $0.id == campaign.id }) else {
            Logger.debug("Campaign \(campaign.id) could not be updated - not found in the repository")
            assertionFailure()
            return nil
        }

        let updatedCampaign = Campaign.updatedCampaign(campaign, withImpressionLeft: newValue)
        list[index] = updatedCampaign
        campaigns.set(value: list)
        userDataCache.cacheCampaignData(list, userIdentifiers: preferenceRepository.getUserIdentifiers())
        return updatedCampaign
    }
}
