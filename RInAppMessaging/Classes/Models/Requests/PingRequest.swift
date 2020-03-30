internal struct PingRequest: Encodable {
    let userIdentifiers: [UserIdentifier]
    let appVersion: String
}
