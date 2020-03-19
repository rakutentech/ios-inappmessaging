/// Model for represent an identifier for Rakuten users.
/// The field 'type' corresponds with the Identification enum.
internal struct UserIdentifier: Encodable, Equatable {

    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case type
    }

    let type: Int
    let identifier: String
}
