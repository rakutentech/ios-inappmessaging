/// Enum for `HTTPRequestable` protcol for http methods.
internal enum HttpMethod: String {
    case post = "POST"
    case get = "GET"
    case delete = "DELETE"
    case put = "PUT"
}

internal enum RequestError: Error {
    case unknown
    case taskFailed(Error)
    case httpError(Int, URLResponse?, Data?)
    case bodyEncodingError(Error?)
}

internal protocol HttpRequestable {

    typealias RequestResult = Result<(data: Data, response: HTTPURLResponse), RequestError>

    var httpSession: URLSession { get }

    func requestFromServerSync(url: URL,
                               httpMethod: HttpMethod,
                               parameters: [String: Any]?,
                               addtionalHeaders: [HeaderAttribute]?) -> RequestResult

    func requestFromServer(url: URL,
                           httpMethod: HttpMethod,
                           parameters: [String: Any]?,
                           addtionalHeaders: [HeaderAttribute]?,
                           completion: @escaping (_ result: RequestResult) -> Void)

    func buildHttpBody(with parameters: [String: Any]?) -> Result<Data, Error>
}

/// Default implementation of HttpRequestable.
extension HttpRequestable {

    func requestFromServerSync(url: URL,
                               httpMethod: HttpMethod,
                               parameters: [String: Any]? = nil,
                               addtionalHeaders: [HeaderAttribute]?) -> RequestResult {

        if Thread.current.isMainThread {
            print("InAppMessaging: Performing HTTP task synchronously on main thread. This should be avoided.")
            assertionFailure()
        }

        var result: RequestResult?

        requestFromServer(
            url: url,
            httpMethod: httpMethod,
            parameters: parameters,
            addtionalHeaders: addtionalHeaders,
            shouldWait: true,
            completion: { result = $0 })

        guard let unwrappedResult = result else {
            CommonUtility.debugPrint("Error: Didn't get any result - completion handler not called!")
            assertionFailure()
            return .failure(.unknown)
        }

        return unwrappedResult
    }

    func requestFromServer(url: URL,
                           httpMethod: HttpMethod,
                           parameters: [String: Any]? = nil,
                           addtionalHeaders: [HeaderAttribute]?,
                           completion: @escaping (_ result: RequestResult) -> Void) {

        requestFromServer(url: url,
                          httpMethod: httpMethod,
                          parameters: parameters,
                          addtionalHeaders: addtionalHeaders,
                          shouldWait: false,
                          completion: completion)
    }

    private func requestFromServer(url: URL,
                                   httpMethod: HttpMethod,
                                   parameters: [String: Any]?,
                                   addtionalHeaders: [HeaderAttribute]?,
                                   shouldWait: Bool,
                                   completion: @escaping (_ result: RequestResult) -> Void) {

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let bodyResult = buildHttpBody(with: parameters)
        switch bodyResult {
        case .success(let body):
            request.httpBody = body
        case .failure(let error):
            completion(.failure(.bodyEncodingError(error)))
            return
        }

        if let headers = addtionalHeaders {
            appendHeaders(headers, forRequest: &request)
        }

        // Semaphore added for synchronous HTTP calls.
        let semaphore = DispatchSemaphore(value: 0)

        // Start HTTP call.
        httpSession.dataTask(with: request, completionHandler: { (data, response, error) in

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

    private func appendHeaders(_ headers: [HeaderAttribute]?, forRequest request: inout URLRequest) {
        headers?.forEach({ header in
            request.addValue(header.value, forHTTPHeaderField: header.key)
        })
    }
}
