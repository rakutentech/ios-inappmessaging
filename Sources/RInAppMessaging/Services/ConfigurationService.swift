import Foundation

internal protocol ConfigurationServiceType {
    func getConfigData() -> Result<ConfigEndpointData, ConfigurationServiceError>
}

internal enum ConfigurationServiceError: Error {
    case requestError(RequestError)
    case jsonDecodingError(Error)
    case tooManyRequestsError
    case missingOrInvalidSubscriptionId
    case unknownSubscriptionId
    case invalidRequestError(UInt)
    case internalServerError(UInt)
    case missingOrInvalidConfigURL
}

internal struct ConfigurationService: ConfigurationServiceType, HttpRequestable {

    private let configurationRepository: ConfigurationRepositoryType
    private(set) var httpSession: URLSession
    var bundleInfo = BundleInfo.self

    init(configurationRepository: ConfigurationRepositoryType) {
        self.configurationRepository = configurationRepository
        self.httpSession = URLSession(configuration: configurationRepository.defaultHttpSessionConfiguration)
    }

    func getConfigData() -> Result<ConfigEndpointData, ConfigurationServiceError> {
        guard let configURLString = configurationRepository.getConfigEndpointURLString(),
              let configURL = URL(string: configURLString) else {
            return .failure(.missingOrInvalidConfigURL)
        }

        let response = requestFromServerSync(
            url: configURL,
            httpMethod: .get,
            addtionalHeaders: buildRequestHeader()
        )

        switch response {
        case .success((let data, _)):
            return parseResponse(data).mapError {
                return ConfigurationServiceError.jsonDecodingError($0)
            }
        case .failure(let requestError):
            switch requestError {
            case .httpError(let statusCode, _, _) where statusCode == 429:
                return .failure(.tooManyRequestsError)
            case .httpError(let statusCode, _, _) where statusCode == 400:
                return .failure(.missingOrInvalidSubscriptionId)
            case .httpError(let statusCode, _, _) where statusCode == 404:
                return .failure(.unknownSubscriptionId)
            case .httpError(let statusCode, _, _) where 300..<500 ~= statusCode:
                return .failure(.invalidRequestError(statusCode))
            case .httpError(let statusCode, _, _) where statusCode >= 500:
                return .failure(.internalServerError(statusCode))
            default:
                return .failure(.requestError(requestError))
            }
        }
    }

    private func parseResponse(_ configResponse: Data) -> Result<ConfigEndpointData, Error> {
        do {
            let response = try JSONDecoder().decode(ConfigEndpointResponse.self, from: configResponse)
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

    private func buildRequestHeader() -> [HeaderAttribute] {
        var headerBuilder = HeaderAttributesBuilder()

        if !headerBuilder.addSubscriptionID(configurationRepository: configurationRepository) {
            Logger.debug("Info.plist must contain a valid InAppMessagingAppSubscriptionID")
            assertionFailure()
        }

        return headerBuilder.build()
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
