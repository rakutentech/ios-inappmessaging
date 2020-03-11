/// Data model for configuration server response.
internal struct GetConfigResponse: Decodable {
    let data: ConfigData

    enum CodingKeys: String, CodingKey {
        case data
    }
}

internal struct ConfigData: Decodable {
    let enabled: Bool
    let endpoints: EndpointURL

    enum CodingKeys: String, CodingKey {
        case enabled
        case endpoints
    }
}

internal struct EndpointURL: Decodable {
    let ping: String
    let displayPermission: String?
    let impression: String?

    enum CodingKeys: String, CodingKey {
        case ping
        case displayPermission
        case impression
    }
}
