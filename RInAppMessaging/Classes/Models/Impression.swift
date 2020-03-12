/// Model for an impression object.
internal struct Impression: Encodable {
    let type: ImpressionType
    let timestamp: Int64
}
