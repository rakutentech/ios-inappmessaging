/// Internal enum for encoding user identifiers
@objc public enum Identification: Int, Codable {
    case rakutenId = 1
    case idTrackingIdentifier
    case userId
}
