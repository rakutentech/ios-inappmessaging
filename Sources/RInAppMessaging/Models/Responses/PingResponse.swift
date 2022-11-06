import Foundation

internal struct PingResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case nextPingMilliseconds = "nextPingMillis"
        case currentPingMilliseconds = "currentPingMillis"
        case data
    }

    let nextPingMilliseconds: Int
    let currentPingMilliseconds: Int64
    let data: [Campaign]
}
