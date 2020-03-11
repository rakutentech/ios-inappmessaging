/// Enum for `HTTPRequestable` protcol for http methods.
internal enum HttpMethod: String {
    case post = "POST"
    case get = "GET"
    case delete = "DELETE"
    case put = "PUT"
}

internal enum RequestError: Error {
    case badData
    case badURL
    case taskFailed(Error)
    case httpError(Int, URLResponse?, Data?)
}

/// Protocol that is conformed to when a class requires HTTP communication abilities.
internal protocol HttpRequestable {

    typealias RequestResult = Result<(data: Data, response: HTTPURLResponse), RequestError>

    /// Generic method for calling an API synchronously.
    /// - Parameter url: The URL of the API to call.
    /// - Parameter httpMethod: The HTTP method used. E.G "POST" / "GET"
    /// - Parameter optionalParams: Any extra parameters to be added into the request body.
    /// - Parameter addtionalHeaders: Any extra parameters to be added into the request header.
    /// - Returns: A response data. `HTTPURLResponse` for success and `RequestError` for failure.
    func requestFromServerSync(url: String,
                               httpMethod: HttpMethod,
                               optionalParams: [String: Any],
                               addtionalHeaders: [Attribute]?) -> RequestResult

    /// Generic method for calling an API asynchronously.
    /// - Parameter url: The URL of the API to call.
    /// - Parameter httpMethod: The HTTP method used. E.G "POST" / "GET"
    /// - Parameter optionalParams: Any extra parameters to be added into the request body.
    /// - Parameter addtionalHeaders: Any extra parameters to be added into the request header.
    /// - Parameter completion: The code to execute when a request has been resolved
    func requestFromServer(url: String,
                           httpMethod: HttpMethod,
                           optionalParams: [String: Any],
                           addtionalHeaders: [Attribute]?,
                           completion: @escaping (_ result: RequestResult) -> Void)

    /// Build out the request body for talking to configuration server.
    /// - Returns: The data of serialized JSON object with the required fields (Optional).
    func buildHttpBody(withOptionalParams optionalParams: [String: Any]?) -> Data?

    /// Append additional headers to the request body.
    /// - Parameter headers: Headers to be added.
    /// - Parameter request: A reference to the request to modify
    func appendHeaders(withHeaders headers: [Attribute]?, forRequest request: inout URLRequest)
}

/// Default implementation of HttpRequestable.
extension HttpRequestable {

    func requestFromServerSync(url: String,
                               httpMethod: HttpMethod,
                               optionalParams: [String: Any] = [:],
                               addtionalHeaders: [Attribute]?) -> RequestResult {

        var dataToReturn: Data?
        var responseToReturn: HTTPURLResponse?
        var errorToReturn: RequestError?

        requestFromServer(
            url: url,
            httpMethod: httpMethod,
            optionalParams: optionalParams,
            addtionalHeaders: addtionalHeaders,
            shouldWait: true,
            completion: { result in
                switch result {
                case .success((let data, let response)):
                    dataToReturn = data
                    responseToReturn = response
                case .failure(let error):
                    errorToReturn = error
                }
            })

        guard let data = dataToReturn,
            let response = responseToReturn else {
                return .failure(errorToReturn ?? .badData)
        }

        return .success((data, response))
    }

    func requestFromServer(url: String,
                           httpMethod: HttpMethod,
                           optionalParams: [String: Any] = [:],
                           addtionalHeaders: [Attribute]?,
                           completion: @escaping (_ result: RequestResult) -> Void) {

        requestFromServer(url: url,
                          httpMethod: httpMethod,
                          optionalParams: optionalParams,
                          addtionalHeaders: addtionalHeaders,
                          shouldWait: false,
                          completion: completion)
    }

    private func requestFromServer(url: String,
                                   httpMethod: HttpMethod,
                                   optionalParams: [String: Any],
                                   addtionalHeaders: [Attribute]?,
                                   shouldWait: Bool,
                                   completion: @escaping (_ result: RequestResult) -> Void) {

        guard let requestUrl = URL(string: url) else {
            completion(.failure(.badURL))
            return
        }

        // Add in the HTTP headers and body.
        var request = URLRequest(url: requestUrl)
        request.httpMethod = httpMethod.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildHttpBody(withOptionalParams: optionalParams)

        if let headers = addtionalHeaders {
            appendHeaders(withHeaders: headers, forRequest: &request)
        }

        // Semaphore added for synchronous HTTP calls.
        let semaphore = DispatchSemaphore(value: 0)

        var dataToReturn: Data?
        var serverResponse: HTTPURLResponse?

        // Start HTTP call.
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in

            defer {
                // Signal completion of HTTP request.
                semaphore.signal()
            }

            if let error = error {
                completion(.failure(.taskFailed(error)))
                print("InAppMessaging: \(error)")
                return
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard 100..<400 ~= statusCode,
                let dataToReturn = data,
                let serverResponse = response as? HTTPURLResponse else {

                    completion(.failure(.httpError(statusCode, response, data)))
                    CommonUtility.debugPrint("InAppMessaging: HTTP call failed.")
                    return
            }

            completion(.success((dataToReturn, serverResponse)))
        }).resume()

        // Pause execution until signal() is called
        // if the request requires the response to act on.
        if shouldWait {
            semaphore.wait()
        }
    }

    func appendHeaders(withHeaders headers: [Attribute]?, forRequest request: inout URLRequest) {
        headers?.forEach({ header in
            request.addValue(header.value, forHTTPHeaderField: header.key)
        })
    }
}
