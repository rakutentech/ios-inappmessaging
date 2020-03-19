/// Utility struct to provide methods for anything campaign related.
internal struct CampaignParser {

    /// Parses the campaign passed in for the view type. E.G modal/slideup/etc.
    /// - Parameter campaign: campaign to parse through.
    /// - Returns: optional value of the view type field of the campaign.
    static func getViewType(campaign: CampaignData) -> CampaignDisplayType? {
        return CampaignDisplayType(rawValue: campaign.type)
    }

    /// Method to parse through each campaign and separate test campaigns from non-tests campaigns.
    /// - Parameter campaigns: the collection of campaigns to parse through.
    /// - Returns: set of test and non-test campaigns.
    /// - Note: Order is important.
    static func splitCampaigns(campaigns: [Campaign]) -> (testCampaigns: [Campaign], nonTestCampaigns: [Campaign]) {
        var testCampaigns = [Campaign]()
        var nonTestCampaigns = [Campaign]()

        for campaign in campaigns {
            if campaign.data.isTest {
                testCampaigns.append(campaign)
            } else {
                nonTestCampaigns.append(campaign)
            }
        }

        return (testCampaigns, nonTestCampaigns)
    }

    /// Parses through a CampaignData object for the delay value inside DisplaySettings.
    /// - Parameter campaign: the campaign object to parse.
    /// - Returns: the delay value.
    static func getDisplaySettingsDelay(from campaign: CampaignData) -> Int? {
        return campaign.messagePayload.messageSettings.displaySettings.delay
    }
}
