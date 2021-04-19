internal protocol ConfigurationServiceType {
    func getConfigData() -> Result<ConfigData, ConfigurationServiceError>
}

internal enum ConfigurationServiceError: Error {
    case requestError(RequestError)
    case jsonDecodingError(Error)
    case tooManyRequestsError
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
            httpMethod: .get,
            addtionalHeaders: nil)

        switch response {
        case .success((let data, _)):
            return parseResponse(data).mapError {
                return ConfigurationServiceError.jsonDecodingError($0)
            }
        case .failure(let requestError):
            switch requestError {
            case .httpError(let statusCode, _, _) where statusCode == 429:
                return .failure(.tooManyRequestsError)
            default:
                return .failure(.requestError(requestError))
            }
        }
    }

    private func parseResponse(_ configResponse: Data) -> Result<ConfigData, Error> {
        do {
            let response = try JSONDecoder().decode(GetConfigResponse.self, from: configResponse)
            return .success(response.data)
        } catch {
            let description = "Failed to parse json"
            Logger.debug("\(description): \(error)")
            return .failure(error)
        }
    }
}

// MARK: - HttpRequestable implementation
extension ConfigurationService {
    private func getConfigRequest() throws -> GetConfigRequest {
        guard let appVersion = bundleInfo.appVersion,
            let appId = bundleInfo.applicationId,
            let sdkVersion = bundleInfo.inAppSdkVersion else {
                Logger.debug("failed creating a request body")
                throw RequestError.missingMetadata
        }
        return GetConfigRequest(
            locale: Locale.current.normalizedIdentifier,
            appVersion: appVersion,
            platform: .ios,
            appId: appId,
            sdkVersion: sdkVersion
        )
    }

    func buildURLRequest(url: URL) -> Result<URLRequest, Error> {
        do {
            let request = try getConfigRequest()
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
            urlComponents?.queryItems = request.toQueryItems
            guard let url = urlComponents?.url else {
                return .failure(RequestError.urlIsNil)
            }
            return .success(URLRequest(url: url))

        } catch let error {
            Logger.debug("failed creating a request - \(error)")
            return .failure(error)
        }
    }

    func buildHttpBody(with parameters: [String: Any]?) -> Result<Data, Error> {
        return .failure(RequestError.bodyIsNil)
    }
}
