internal struct UserIdentifier: Encodable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case type
    }

    let type: Identification
    let identifier: String
}
