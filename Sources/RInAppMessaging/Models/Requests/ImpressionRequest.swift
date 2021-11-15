internal struct ImpressionRequest: Codable {
    let campaignId: String
    let isTest: Bool
    let appVersion: String
    let sdkVersion: String
    let impressions: [Impression]
    let userIdentifiers: [UserIdentifier]
}
