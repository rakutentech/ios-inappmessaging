internal struct GetConfigResponse: Decodable {
    let data: ConfigData
}

internal struct ConfigData: Decodable {
    let enabled: Bool
    let endpoints: EndpointURL
}

internal struct EndpointURL: Decodable {
    let ping: URL
    let displayPermission: URL?
    let impression: URL?
}
