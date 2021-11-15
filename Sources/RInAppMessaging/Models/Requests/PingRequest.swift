internal struct PingRequest: Codable {
    let userIdentifiers: [UserIdentifier]
    let appVersion: String
}
