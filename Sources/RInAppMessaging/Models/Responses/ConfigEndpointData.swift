import struct Foundation.URL

internal struct ConfigEndpointResponse: Decodable {
    let data: ConfigEndpointData
}

internal struct ConfigEndpointData: Decodable {
    let rolloutPercentage: Int
    let endpoints: EndpointURL?
}

internal struct EndpointURL: Decodable, Equatable {
    let ping: URL?
    let displayPermission: URL?
    let impression: URL?
}
