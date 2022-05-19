internal struct Impression: Codable, Equatable {
    let type: ImpressionType
    let timestamp: Int64
}

extension Array where Element == Impression {
    func encodeForAnalytics() -> [Any] {
        map { impression in
            [Constants.RAnalytics.Keys.action: impression.type.rawValue,
             Constants.RAnalytics.Keys.timestamp: impression.timestamp]
        }
    }
}
