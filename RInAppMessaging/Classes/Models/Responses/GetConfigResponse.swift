internal struct GetConfigResponse: Decodable {
    let data: ConfigData
}

internal struct ConfigData: Decodable {
    let rolloutPercentage: Int
    let endpoints: EndpointURL?
}

internal struct EndpointURL: Decodable, Equatable {
    let ping: URL?
    let displayPermission: URL?
    let impression: URL?
}
