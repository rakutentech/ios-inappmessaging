/// Model of the request body for ping request.
internal struct PingRequest: Encodable {
    let userIdentifiers: [UserIdentifier]
    let appVersion: String
}
