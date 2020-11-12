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

    /// Decrements number of impressionsLeft for provided campaign in the repository.
    /// - Parameter campaign: The campaign to update impressionsLeft value.
    /// - Returns: A new campaign structure with updated impressionsLeft value
    /// or `nil` if campaign couldn't be found in the repository.
    @discardableResult
    func decrementImpressionsLeftInCampaign(_ campaign: Campaign) -> Campaign?

    /// Increments number of impressionsLeft for provided campaign in the repository.
    /// - Parameter campaign: The campaign to update impressionsLeft value.
    /// - Returns: A new campaign structure with updated impressionsLeft value
    /// or `nil` if campaign couldn't be found in the repository.
    @discardableResult
    func incrementImpressionsLeftInCampaign(_ campaign: Campaign) -> Campaign?
}

/// Repository to store campaigns retrieved from ping request.
internal class CampaignRepository: CampaignRepositoryType {

    private let campaigns = LockableObject([Campaign]())
    private(set) var lastSyncInMilliseconds: Int64?
    var list: [Campaign] {
        return campaigns.get()
    }
    var resourcesToLock: [LockableResource] {
        return [campaigns]
    }

    func syncWith(list: [Campaign], timestampMilliseconds: Int64) {
        lastSyncInMilliseconds = timestampMilliseconds
        let oldList = self.campaigns.get()
        var newList = [Campaign]()

        // Preserving information about opt out state in case when server didn't process impressions sent from the SDK yet.
        // There is an assumption that maxImpressions value from the server is the most recent one.
        // (Considering any possible updates to the campaign in the IAM web dashboard)
        list.forEach { newCampaign in
            var updatedCampaign = newCampaign
            if let oldCampaign = oldList.first(where: { $0.id == newCampaign.id }) {
                updatedCampaign = Campaign.updatedCampaign(updatedCampaign,
                    asOptedOut: oldCampaign.isOptedOut)
            }
            newList.append(updatedCampaign)
        }
        self.campaigns.set(value: newList)
    }

    @discardableResult
    func optOutCampaign(_ campaign: Campaign) -> Campaign? {
        var list = self.campaigns.get()
        guard let index = list.firstIndex(where: { $0.id == campaign.id }) else {
            CommonUtility.debugPrint("Campaign \(campaign.id) cannot be updated - not found in repository")
            return nil
        }

        let updatedCampaign = Campaign.updatedCampaign(campaign, asOptedOut: true)
        list[index] = updatedCampaign
        self.campaigns.set(value: list)
        return updatedCampaign
    }

    @discardableResult
    func decrementImpressionsLeftInCampaign(_ campaign: Campaign) -> Campaign? {
        let updatedCampaign = Campaign.updatedCampaign(campaign, withImpressionLeft: max(0, campaign.impressionsLeft - 1))
        return updateCampaignInTheList(updatedCampaign) ? updatedCampaign : nil
    }

    @discardableResult
    func incrementImpressionsLeftInCampaign(_ campaign: Campaign) -> Campaign? {
        let updatedCampaign = Campaign.updatedCampaign(campaign, withImpressionLeft: campaign.impressionsLeft + 1)
        return updateCampaignInTheList(updatedCampaign) ? updatedCampaign : nil
    }

    private func updateCampaignInTheList(_ campaign: Campaign) -> Bool {
        var list = campaigns.get()
        guard let index = list.firstIndex(where: { $0.id == campaign.id }) else {
            CommonUtility.debugPrint("Campaign \(campaign.id) cannot be updated - not found in repository")
            return false
        }
        list[index] = campaign
        campaigns.set(value: list)
        return true
    }
}
