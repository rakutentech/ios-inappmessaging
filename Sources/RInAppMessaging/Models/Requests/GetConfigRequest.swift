import struct Foundation.URLQueryItem

internal struct GetConfigRequest: Codable {
    private enum CodingKeys: String, CodingKey {
        case locale
        case appVersion
        case platform
        case appId
        case sdkVersion
        case rmcSdkVersion
    }

    let locale: String
    let appVersion: String
    let platform: Platform
    let appId: String
    let sdkVersion: String
    let rmcSdkVersion: String?
}

extension GetConfigRequest {
    var toQueryItems: [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: CodingKeys.platform.rawValue, value: "\(platform.rawValue)"))
        queryItems.append(URLQueryItem(name: CodingKeys.appId.rawValue, value: appId))
        queryItems.append(URLQueryItem(name: CodingKeys.appVersion.rawValue, value: appVersion))
        queryItems.append(URLQueryItem(name: CodingKeys.sdkVersion.rawValue, value: sdkVersion))
        queryItems.append(URLQueryItem(name: CodingKeys.locale.rawValue, value: locale))
        if let rmcSdkVersion = rmcSdkVersion {
            queryItems.append(URLQueryItem(name: CodingKeys.rmcSdkVersion.rawValue, value: rmcSdkVersion))
        }
        return queryItems
    }
}
