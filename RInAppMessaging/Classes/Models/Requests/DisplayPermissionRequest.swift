internal struct DisplayPermissionRequest: Codable {
    private enum CodingKeys: String, CodingKey {
        case subscriptionId
        case campaignId
        case userIdentifiers
        case platform
        case appVersion
        case sdkVersion
        case locale
        case lastPingInMilliseconds = "lastPingInMillis"
    }

    let subscriptionId: String
    let campaignId: String
    let userIdentifiers: [UserIdentifier]
    let platform: Platform
    let appVersion: String
    let sdkVersion: String
    let locale: String
    let lastPingInMilliseconds: Int64
}
