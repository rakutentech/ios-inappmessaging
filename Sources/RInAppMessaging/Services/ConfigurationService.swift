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
    private var eventLogger: EventLoggerSendable
    var bundleInfo = BundleInfo.self

    init(configurationRepository: ConfigurationRepositoryType,
         eventLogger: EventLoggerSendable) {
        self.configurationRepository = configurationRepository
        self.eventLogger = eventLogger
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
                eventLogger.logEvent(eventType: .warning, errorCode: Constants.IAMErrorCode.configJsonDecodingError.errorCode + $0.localizedDescription, errorMessage: Constants.IAMErrorCode.configJsonDecodingError.errorMessage)
                return ConfigurationServiceError.jsonDecodingError($0)
            }
        case .failure(let requestError):
            switch requestError {
            case .httpError(let statusCode, _, _) where statusCode == 429:
                eventLogger.logEvent(eventType: .critical, errorCode: Constants.IAMErrorCode.configTooManyRequestsError.errorCode + String(statusCode), errorMessage: Constants.IAMErrorCode.configTooManyRequestsError.errorMessage)
                return .failure(.tooManyRequestsError)
            case .httpError(let statusCode, _, _) where statusCode == 400:
                eventLogger.logEvent(eventType: .critical, errorCode: Constants.IAMErrorCode.configMissingOrInvalidSubscriptionId.errorCode + String(statusCode), errorMessage:Constants.IAMErrorCode.configMissingOrInvalidSubscriptionId.errorMessage)
                return .failure(.missingOrInvalidSubscriptionId)
            case .httpError(let statusCode, _, _) where statusCode == 404:
                eventLogger.logEvent(eventType: .critical, errorCode: Constants.IAMErrorCode.configUnknownSubscriptionId.errorCode + String(statusCode), errorMessage: Constants.IAMErrorCode.configUnknownSubscriptionId.errorMessage)
                return .failure(.unknownSubscriptionId)
            case .httpError(let statusCode, _, _) where 300..<500 ~= statusCode:
                eventLogger.logEvent(eventType: .critical, errorCode: Constants.IAMErrorCode.configInvalidRequestError.errorCode + String(statusCode), errorMessage: Constants.IAMErrorCode.configInvalidRequestError.errorMessage)
                return .failure(.invalidRequestError(statusCode))
            case .httpError(let statusCode, _, _) where statusCode >= 500:
                eventLogger.logEvent(eventType: .critical, errorCode:Constants.IAMErrorCode.configInternalServerError.errorCode + String(statusCode), errorMessage: Constants.IAMErrorCode.configInternalServerError.errorMessage)
                return .failure(.internalServerError(statusCode))
            default:
                eventLogger.logEvent(eventType: .critical, errorCode:Constants.IAMErrorCode.configRequestError.errorCode + requestError.localizedDescription, errorMessage: Constants.IAMErrorCode.configRequestError.errorMessage)
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
              let appId = bundleInfo.applicationId else {
            Logger.debug("failed creating a request body")
            throw RequestError.missingMetadata
        }
        
        return GetConfigRequest(
            locale: Locale.current.normalizedIdentifier,
            appVersion: appVersion,
            platform: .ios,
            appId: appId,
            sdkVersion: Constants.Versions.sdkVersion,
            rmcSdkVersion: bundleInfo.rmcSdkVersion
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
        .failure(RequestError.bodyIsNil)
    }
}
