internal struct GetConfigRequest: Codable {
    let locale: String
    let appVersion: String
    let platform: Int
    let appId: String
    let sdkVersion: String
}
