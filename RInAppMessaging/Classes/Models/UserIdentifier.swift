internal struct UserIdentifier: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case type
    }

    let type: Identification
    let identifier: String
}
