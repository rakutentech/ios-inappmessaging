import struct Foundation.Date

/// Protocol that is conformed to when impression tracking is needed.
internal protocol ImpressionTrackable: AnyObject {
    var impressions: [Impression] { get set }
    var impressionService: ImpressionServiceType { get }

    /// Log the impression of a campaign.
    /// - Parameter type: Enum type of the impression.
    /// - Parameter properties: Optional properties to send.
    func logImpression(type: ImpressionType)

    /// Called at the end of an action function from a campaign. This will pack
    /// up all the neccessary data and send it to the impression endpoint.
    /// - Parameter campaign: The campaign from which impressions came
    func sendImpressions(for campaign: Campaign)
}

extension ImpressionTrackable {
    func sendImpressions(for campaign: Campaign) {
        impressionService.pingImpression(
            impressions: impressions,
            campaignData: campaign.data)
    }

    func logImpression(type: ImpressionType) {
        impressions.append(
            Impression(
                type: type,
                timestamp: Date().millisecondsSince1970
            )
        )
    }
}
