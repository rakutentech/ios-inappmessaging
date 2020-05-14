internal protocol ConfigurationServiceType {
    func getConfigData() -> Result<ConfigData, ConfigurationServiceError>
}

internal enum ConfigurationServiceError: Error {
    case requestError(RequestError)
    case jsonDecodingError(Error)
}

internal struct ConfigurationService: ConfigurationServiceType, HttpRequestable {

    private let configURL: URL
    private(set) var httpSession: URLSession
    var bundleInfo = BundleInfo.self

    init(configURL: URL, sessionConfiguration: URLSessionConfiguration) {
        self.configURL = configURL
        self.httpSession = URLSession(configuration: sessionConfiguration)
    }

    func getConfigData() -> Result<ConfigData, ConfigurationServiceError> {
        let response = requestFromServerSync(
            url: configURL,
            httpMethod: .post,
            addtionalHeaders: nil)

        switch response {
        case .success((let data, _)):
            return parseResponse(data).mapError {
                return ConfigurationServiceError.jsonDecodingError($0)
            }
        case .failure(let requestError):
            return .failure(.requestError(requestError))
        }
    }

    private func parseResponse(_ configResponse: Data) -> Result<ConfigData, Error> {
        do {
            let response = try JSONDecoder().decode(GetConfigResponse.self, from: configResponse)
            return .success(response.data)
        } catch {
            let description = "Failed to parse json"
            CommonUtility.debugPrint("\(description): \(error)")
            return .failure(error)
        }
    }
}

// MARK: - HttpRequestable implementation
extension ConfigurationService {

    func buildHttpBody(with parameters: [String: Any]?) -> Result<Data, Error> {

        guard let appVersion = bundleInfo.appVersion,
            let appId = bundleInfo.applicationId,
            let sdkVersion = bundleInfo.inAppSdkVersion else {

                CommonUtility.debugPrint("failed creating a request body")
                assertionFailure()
                return .failure(RequestError.unknown)
        }

        let getConfigRequest = GetConfigRequest(
            locale: Locale.current.normalizedIdentifier,
            appVersion: appVersion,
            platform: .ios,
            appId: appId,
            sdkVersion: sdkVersion
        )

        do {
            let body = try JSONEncoder().encode(getConfigRequest)
            return .success(body)
        } catch let error {
            CommonUtility.debugPrint("failed creating a request body - \(error)")
            return .failure(error)
        }
    }
}
