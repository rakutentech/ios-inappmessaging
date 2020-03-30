internal struct ImpressionRequest: Encodable {
    let campaignId: String
    let isTest: Bool
    let appVersion: String
    let sdkVersion: String
    let impressions: [Impression]
    let userIdentifiers: [UserIdentifier]
}
