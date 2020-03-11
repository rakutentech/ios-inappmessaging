internal protocol CampaignRepositoryType: AnyObject, Lockable {
    var list: [Campaign] { get }
    var lastSyncInMilliseconds: Int? { get }

    /// Used to sync with list from the server. Server list is considered as source of truth.
    /// Order must be preserved.
    func syncWith(list: [Campaign], timestampMilliseconds: Int)

    /// Opts out the campaign and updates the repository.
    /// - Parameter campaign: The campaign to opt out.
    /// - Returns: A new campaign structure with updated opt out status
    /// or `nil` if campaign couldn't be found in the repository.
    func optOutCampaign(_ campaign: Campaign) -> Campaign?

    /// Decrements number of impressionsLeft for provided campaign in the repository.
    /// - Parameter campaign: The campaign to update impressionsLeft value.
    /// - Returns: A new campaign structure with updated impressionsLeft value
    /// or `nil` if campaign couldn't be found in the repository.
    func decrementImpressionsLeftInCampaign(_ campaign: Campaign) -> Campaign?
}

/// Repository to store campaigns retrieved from ping request.
internal class CampaignRepository: CampaignRepositoryType {

    private let campaigns = LockableObject([Campaign]())
    private(set) var lastSyncInMilliseconds: Int?
    var list: [Campaign] {
        return campaigns.get()
    }
    var resourcesToLock: [LockableResource] {
        return [campaigns]
    }

    func syncWith(list: [Campaign], timestampMilliseconds: Int) {
        lastSyncInMilliseconds = timestampMilliseconds
        let oldList = self.campaigns.get()
        var newList = [Campaign]()

        // Preserving information about opt out state and number of impressions left
        // is necessary in case when server didn't process impressions sent from the SDK yet.
        // maxImpressions value from the server will decrease (on the server) after every impression
        // causing situation when SDK could loose track on how many more times campaign message should be displayed.
        // In the future the number of times campaign was displayed should be stored on the server
        // which will avoid using this logic and it will also allow updating maxImpressions in the IAM web dashboard.
        list.forEach { newCampaign in
            var updatedCampaign = newCampaign
            if let oldCampaign = oldList.first(where: { $0.id == newCampaign.id }) {
                updatedCampaign = Campaign.updatedCampaign(updatedCampaign,
                    withImpressionLeft: min(newCampaign.data.maxImpressions, oldCampaign.impressionsLeft))
                updatedCampaign = Campaign.updatedCampaign(updatedCampaign,
                    asOptedOut: oldCampaign.isOptedOut)
            }
            newList.append(updatedCampaign)
        }
        self.campaigns.set(value: newList)
    }

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

    func decrementImpressionsLeftInCampaign(_ campaign: Campaign) -> Campaign? {
        var list = self.campaigns.get()
        guard let index = list.firstIndex(where: { $0.id == campaign.id }) else {
            CommonUtility.debugPrint("Campaign \(campaign.id) cannot be updated - not found in repository")
            return nil
        }

        let updatedCampaign = Campaign.updatedCampaign(campaign, withImpressionLeft: campaign.impressionsLeft - 1)
        list[index] = updatedCampaign
        self.campaigns.set(value: list)
        return updatedCampaign
    }
}
