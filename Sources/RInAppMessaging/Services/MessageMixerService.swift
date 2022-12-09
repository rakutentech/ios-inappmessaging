import Foundation

internal protocol MessageMixerServiceType {
    func ping() -> Result<PingResponse, MessageMixerServiceError>
}

internal enum MessageMixerServiceError: Error {
    case requestError(RequestError)
    case jsonDecodingError(Error)
    case invalidConfiguration
    case tooManyRequestsError
    case internalServerError(UInt)
    case invalidRequestError(UInt)
}

internal class MessageMixerService: MessageMixerServiceType, HttpRequestable {

    private let accountRepository: AccountRepositoryType
    private let configurationRepository: ConfigurationRepositoryType

    private(set) var httpSession: URLSession
    var bundleInfo = BundleInfo.self

    init(accountRepository: AccountRepositoryType,
         configurationRepository: ConfigurationRepositoryType) {

        self.accountRepository = accountRepository
        self.configurationRepository = configurationRepository
        httpSession = URLSession(configuration: configurationRepository.defaultHttpSessionConfiguration)
    }

    func ping() -> Result<PingResponse, MessageMixerServiceError> {

        guard let mixerServerUrl = configurationRepository.getEndpoints()?.ping else {
            let error = "Error retrieving InAppMessaging Mixer Server URL"
            Logger.debug(error)
            return .failure(.invalidConfiguration)
        }

        let response = requestFromServerSync(
            url: mixerServerUrl,
            httpMethod: .post,
            addtionalHeaders: buildRequestHeader()
        )

        switch response {
        case .success((let data, _)):
            return parseResponse(data).mapError {
                return MessageMixerServiceError.jsonDecodingError($0)
            }
        case .failure(let requestError):
            switch requestError {
            case .httpError(let statusCode, _, _) where statusCode == 429:
                return .failure(.tooManyRequestsError)
            case .httpError(let statusCode, _, _) where 300..<500 ~= statusCode:
                return .failure(.invalidRequestError(statusCode))
            case .httpError(let statusCode, _, _) where statusCode >= 500:
                return .failure(.internalServerError(statusCode))
            default:
                return .failure(.requestError(requestError))
            }
        }
    }

    private func parseResponse(_ response: Data) -> Result<PingResponse, Error> {
        do {
            let response = try JSONDecoder().decode(PingResponse.self, from: response)
            return .success(response)
        } catch {
            let description = "Failed to parse json"
            Logger.debug("\(description): \(error)")
            return .failure(error)
        }
    }
}

// MARK: - HttpRequestable implementation
extension MessageMixerService {

    func buildHttpBody(with parameters: [String: Any]?) -> Result<Data, Error> {

        guard let appVersion = bundleInfo.appVersion else {
            Logger.debug("failed creating a request body")
            return .failure(RequestError.missingMetadata)
        }

        let pingRequest = PingRequest(
            userIdentifiers: accountRepository.getUserIdentifiers(),
            appVersion: appVersion,
            supportedCampaignTypes: [.pushPrimer, .regular])

        do {
            let body = try JSONEncoder().encode(pingRequest)
            return .success(body)
        } catch let error {
            Logger.debug("failed creating a request body - \(error)")
            return .failure(error)
        }
    }

    private func buildRequestHeader() -> [HeaderAttribute] {
        var builder = HeaderAttributesBuilder()
        builder.addSubscriptionID(configurationRepository: configurationRepository)
        builder.addDeviceID()
        builder.addAccessToken(accountRepository: accountRepository)

        return builder.build()
    }
}
