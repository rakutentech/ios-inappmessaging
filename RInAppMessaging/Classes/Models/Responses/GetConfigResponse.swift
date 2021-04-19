internal struct GetConfigResponse: Decodable {
    let data: ConfigData
}

internal struct ConfigData: Decodable {
    let rolloutPercentage: Int
    let endpoints: EndpointURL?
}

extension ConfigData {
    // Temporary property - It has to be removed in the ticket SDKCF-3663
    var enabled: Bool {
        rolloutPercentage > 0
    }
}

internal struct EndpointURL: Decodable, Equatable {
    let ping: URL?
    let displayPermission: URL?
    let impression: URL?
}
