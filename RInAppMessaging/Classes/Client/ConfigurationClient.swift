/// Class to handle communication with the configuration server.
internal class ConfigurationClient: HttpRequestable, ErrorReportable, ReachabilityObserver {

    weak var errorDelegate: ErrorDelegate?

    private let reachability: ReachabilityType?
    private let configURL: String
    private var retryDelayMillis = Int32(10000)
    private var lastRequestTime: TimeInterval = 0
    private let dataValidityPeriod: TimeInterval = 60

    private var latestEndpoints: EndpointURL?
    private var latestIsEnabled: Bool?
    private var onConnectionResumed: (() -> Void)?

    init(reachability: ReachabilityType?, configURL: String) {
        self.reachability = reachability
        self.configURL = configURL
    }

    /// Return endpoints data.
    /// Data is refreshed by calling `isConfigEnabled`
    /// - Returns: Endpoints data (Optional).
    /// - Note: `isConfigEnabled` should be called at least once prior calling this method.
    func getEndpoints() -> EndpointURL? {
        return latestEndpoints
    }

    /// Parse the configuration server's response for the enabled flag.
    /// Returns false by default.
    /// - Parameter retryHandler: Handler that will be called after failed request (with a delay) or when connection has been restored.
    /// - Returns: Value of the enabled flag.
    /// - Note: Function will return `false` in case of request failure
    func isConfigEnabled(retryHandler: @escaping () -> Void) -> Bool {

        if let latestIsEnabled = latestIsEnabled, isLatestDataValid() {
            return latestIsEnabled
        }

        // Not initialized reachability is treated as connection available
        guard reachability?.connection.isAvailable != false else {
            onConnectionResumed = retryHandler
            reachability?.addObserver(self)
            return false
        }

        return fetchNewData(retryHandler: retryHandler).isEnabled ?? false
    }

    /// Request body for Configuration client to get get-config endpoint.
    /// - Parameter optionalParams: Additional params to be added to the request body.
    /// - Returns: Optional serialized data for the request body.
    func buildHttpBody(withOptionalParams optionalParams: [String: Any]?) -> Data? {

        guard let locale = Locale.formattedCode,
            let appVersion = Bundle.appVersion,
            let appId = Bundle.applicationId,
            let sdkVersion = Bundle.inAppSdkVersion else {

                reportError(description: "InAppMessaging: failed creating a request body.", data: nil)
                assertionFailure()
                return nil
        }

        let getConfigRequest = GetConfigRequest(
            locale: locale,
            appVersion: appVersion,
            platform: PlatformEnum.ios.rawValue,
            appId: appId,
            sdkVersion: sdkVersion
        )

        do {
            return try JSONEncoder().encode(getConfigRequest)
        } catch let error {
            let description = "InAppMessaging: failed creating a request body."
            print("\(description): \(error)")
            reportError(description: description, data: error)
        }
        return nil
    }

    private func fetchNewData(retryHandler: @escaping () -> Void) -> (isEnabled: Bool?, endpoints: EndpointURL?) {
        lastRequestTime = Date().timeIntervalSince1970
        let response = requestFromServerSync(
            url: configURL,
            httpMethod: .post,
            addtionalHeaders: nil)

        switch response {
        case .failure(let error):
            let description = "InAppMessaging: Error calling config server. Retrying in \(retryDelayMillis)ms"
            CommonUtility.debugPrint(description)
            reportError(description: description, data: error)
            WorkScheduler.scheduleTask(milliseconds: Int(retryDelayMillis), closure: retryHandler, wallDeadline: true)
            // Exponential backoff for pinging Configuration server.
            retryDelayMillis = retryDelayMillis.multipliedReportingOverflow(by: 2).partialValue
            return (nil, nil)

        case .success((let data, _)):
            parseConfigResponse(configResponse: data)
            return (latestIsEnabled, latestEndpoints)
        }
    }

    /// Parse the response retrieve from configuration server for the 'enabled' flag and endpoints.
    /// - Parameter configResponse: Response as a dictionary equivalent.
    private func parseConfigResponse(configResponse: Data) {
        do {
            let response = try JSONDecoder().decode(GetConfigResponse.self, from: configResponse)
            latestEndpoints = response.data.endpoints
            latestIsEnabled = response.data.enabled

        } catch let error {
            let description = "InAppMessaging: Failed to parse json"
            CommonUtility.debugPrint("\(description): \(error)")
            reportError(description: description, data: error)
        }
    }

    private func isLatestDataValid() -> Bool {
        return Date().timeIntervalSince1970 - lastRequestTime <= dataValidityPeriod
    }

    // MARK: - ReachabilityObserver

    func reachabilityChanged(_ reachability: ReachabilityType) {
        guard let onConnectionResumed = onConnectionResumed,
            reachability.connection.isAvailable else {
            return
        }

        reachability.removeObserver(self)
        self.onConnectionResumed = nil
        onConnectionResumed()
    }
}
