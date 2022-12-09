import Foundation
import Quick
import Nimble

#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsNimble
import class RSDKUtilsTestHelpers.URLSessionMock
#endif

@testable import RInAppMessaging

// swiftlint:disable:next type_body_length
class HttpRequestableSpec: QuickSpec {

    // swiftlint:disable:next function_body_length
    override func spec() {

        describe("HttpRequestable objects") {

            let requestQueue = DispatchQueue(label: "iam.test.request")
            var httpRequestable: HttpRequestableObject!

            beforeEach {
                httpRequestable = HttpRequestableObject()
            }

            afterEach {
                httpRequestable = nil // force deallocation of .httpSessionMock
            }

            context("when calling requestFromServerSync") {

                it("will send a reqest using provided URL") {
                    let url = URL(string: "https://test.url")!
                    waitUntil { done in
                        requestQueue.async {
                            _ = httpRequestable.requestFromServerSync(url: url,
                                                                      httpMethod: .put,
                                                                      parameters: nil,
                                                                      addtionalHeaders: nil)
                            done()
                        }
                    }

                    let request = httpRequestable.httpSessionMock.sentRequest
                    expect(request).toNot(beNil())
                    expect(request?.url).to(equal(url))
                }

                it("will send a reqest using provided method") {
                    waitUntil { done in
                        requestQueue.async {
                            _ = httpRequestable.requestFromServerSync(url: URL(string: "https://test.url")!,
                                                                      httpMethod: .put,
                                                                      parameters: nil,
                                                                      addtionalHeaders: nil)
                            done()
                        }
                    }

                    let request = httpRequestable.httpSessionMock.sentRequest
                    expect(request).toNot(beNil())
                    expect(request?.httpMethod).to(equal(HttpMethod.put.rawValue))
                }

                it("will send a request with provided data") {
                    let data = "data".data(using: .ascii)!
                    httpRequestable.bodyData = data
                    waitUntil { done in
                        requestQueue.async {
                            _ = httpRequestable.requestFromServerSync(url: URL(string: "https://test.url")!,
                                                                      httpMethod: .put,
                                                                      parameters: nil,
                                                                      addtionalHeaders: nil)
                            done()
                        }
                    }

                    let request = httpRequestable.httpSessionMock.sentRequest
                    expect(request).toNot(beNil())
                    expect(request?.httpBody).to(equal(data))
                }

                it("will always send requests with application/json Content-Type header") {
                    waitUntil { done in
                        requestQueue.async {
                            _ = httpRequestable.requestFromServerSync(url: URL(string: "https://test.url")!,
                                                                      httpMethod: .put,
                                                                      parameters: nil,
                                                                      addtionalHeaders: nil)
                            done()
                        }
                    }

                    let request = httpRequestable.httpSessionMock.sentRequest
                    expect(request).toNot(beNil())
                    expect(request?.allHTTPHeaderFields).to(equal(["Content-Type": "application/json"]))
                }

                it("will send a request with application/json Content-Type header along with other provided headers") {
                    let headers = [HeaderAttribute(key: "1", value: "abc"),
                                    HeaderAttribute(key: "a", value: "2")]
                    waitUntil { done in
                        requestQueue.async {
                            _ = httpRequestable.requestFromServerSync(url: URL(string: "https://test.url")!,
                                                                      httpMethod: .put,
                                                                      parameters: nil,
                                                                      addtionalHeaders: headers)
                            done()
                        }
                    }

                    let request = httpRequestable.httpSessionMock.sentRequest
                    let headersDict = headers.reduce(into: ["Content-Type": "application/json"], { (acc, header) in
                        acc[header.key] = header.value
                    })
                    expect(request).toNot(beNil())
                    expect(request?.allHTTPHeaderFields).to(equal(headersDict))
                }

                it("will return an error if building body has failed") {
                    httpRequestable.bodyError = .bodyError

                    waitUntil { done in
                        requestQueue.async {
                            let result = httpRequestable.requestFromServerSync(
                                url: URL(string: "https://test.url")!,
                                httpMethod: .put,
                                parameters: nil,
                                addtionalHeaders: nil)

                            let error = result.getError()
                            expect(error).to(matchError(RequestError.self))

                            guard case .bodyEncodingError(let enclosedError) = error,
                                let bodyError = enclosedError as? HttpRequestableObjectError,
                                case .bodyError = bodyError else {

                                fail("Unexpected error type \(String(describing: error)). Expected .bodyEncodingError(.bodyError)")
                                done()
                                return
                            }

                            done()
                        }
                    }
                }

                it("will return an error if session error occured") {
                    httpRequestable.httpSessionMock.responseError = HttpRequestableObjectError.sessionError

                    waitUntil { done in
                        requestQueue.async {
                            let result = httpRequestable.requestFromServerSync(
                                url: URL(string: "https://test.url")!,
                                httpMethod: .put,
                                parameters: nil,
                                addtionalHeaders: nil)

                            let error = result.getError()
                            expect(error).to(matchError(RequestError.self))

                            guard case .taskFailed(let enclosedError) = error,
                                let sessionError = enclosedError as? HttpRequestableObjectError,
                                case .sessionError = sessionError else {

                                    fail("Unexpected error type \(String(describing: error)). Expected .taskFailed(.sessionError)")
                                    done()
                                    return
                            }

                            done()
                        }
                    }
                }

                it("will return an error for code indicating an error <100, 300)") {
                    for code: UInt in [300, 400, 404, 422, 500, 501, 666] {

                        httpRequestable.httpSessionMock.responseData = "data".data(using: .ascii)!
                        httpRequestable.httpSessionMock.httpResponse = HTTPURLResponse(
                            url: URL(string: "https://test.url")!,
                            statusCode: Int(code),
                            httpVersion: nil,
                            headerFields: nil)

                        waitUntil { done in
                            requestQueue.async {
                                let result = httpRequestable.requestFromServerSync(
                                    url: URL(string: "https://test.url")!,
                                    httpMethod: .put,
                                    parameters: nil,
                                    addtionalHeaders: nil)

                                let error = result.getError()
                                expect(error).to(matchError(RequestError.self))

                                guard case .httpError(let statusCode, _, _) = error else {

                                    fail("Unexpected error type \(String(describing: error)). Expected .httpError")
                                    done()
                                    return
                                }

                                expect(statusCode).to(equal(code))
                                done()
                            }
                        }
                    }
                }

                it("will return an error if no response was returned") {
                    httpRequestable.httpSessionMock.responseData = "data".data(using: .ascii)!
                    httpRequestable.httpSessionMock.httpResponse = nil

                    waitUntil { done in
                        requestQueue.async {
                            let result = httpRequestable.requestFromServerSync(
                                url: URL(string: "https://test.url")!,
                                httpMethod: .put,
                                parameters: nil,
                                addtionalHeaders: nil)

                            let error = result.getError()
                            expect(error).to(matchError(RequestError.self))

                            guard case .httpError = error else {
                                fail("Unexpected error type \(String(describing: error)). Expected .httpError")
                                done()
                                return
                            }

                            done()
                        }
                    }
                }

                it("will return an error if no data was returned") {
                    httpRequestable.httpSessionMock.responseData = nil
                    httpRequestable.httpSessionMock.httpResponse = HTTPURLResponse(
                        url: URL(string: "https://test.url")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil)

                    waitUntil { done in
                        requestQueue.async {
                            let result = httpRequestable.requestFromServerSync(
                                url: URL(string: "https://test.url")!,
                                httpMethod: .put,
                                parameters: nil,
                                addtionalHeaders: nil)

                            let error = result.getError()
                            expect(error).to(matchError(RequestError.self))

                            guard case .httpError = error else {
                                fail("Unexpected error type \(String(describing: error)). Expected .httpError")
                                done()
                                return
                            }

                            done()
                        }
                    }
                }

                it("will return success if data is present and response contains valid code") {
                    for code in [100, 200, 201] {

                        httpRequestable.httpSessionMock.responseData = "data".data(using: .ascii)!
                        httpRequestable.httpSessionMock.httpResponse = HTTPURLResponse(
                            url: URL(string: "https://test.url")!,
                            statusCode: code,
                            httpVersion: nil,
                            headerFields: nil)

                        waitUntil { done in
                            requestQueue.async {
                                let result = httpRequestable.requestFromServerSync(
                                    url: URL(string: "https://test.url")!,
                                    httpMethod: .put,
                                    parameters: nil,
                                    addtionalHeaders: nil)

                                expect {
                                    try result.get()
                                }.toNot(throwError())
                                done()
                            }
                        }
                    }
                }

                it("will return response and data objects when call succeeded") {
                    let data = "data".data(using: .ascii)!
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.url")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil)

                    httpRequestable.httpSessionMock.responseData = data
                    httpRequestable.httpSessionMock.httpResponse = response

                    waitUntil { done in
                        requestQueue.async {
                            let result = httpRequestable.requestFromServerSync(
                                url: URL(string: "https://test.url")!,
                                httpMethod: .put,
                                parameters: nil,
                                addtionalHeaders: nil)

                            let resultData = try? result.get()
                            expect(resultData).toNot(beNil())
                            expect(resultData?.data).to(equal(data))
                            expect(resultData?.response).to(equal(response))
                            done()
                        }
                    }
                }
            }

            context("when calling requestFromServer") {

                it("will send a reqest using provided URL") {
                    let url = URL(string: "https://test.url")!
                    waitUntil { done in
                        httpRequestable.requestFromServer(url: url,
                                                          httpMethod: .put,
                                                          parameters: nil,
                                                          addtionalHeaders: nil,
                                                          completion: { _ in done() })
                    }

                    let request = httpRequestable.httpSessionMock.sentRequest
                    expect(request).toNot(beNil())
                    expect(request?.url).to(equal(url))
                }

                it("will send a reqest using provided method") {
                    waitUntil { done in
                        httpRequestable.requestFromServer(url: URL(string: "https://test.url")!,
                                                          httpMethod: .put,
                                                          parameters: nil,
                                                          addtionalHeaders: nil,
                                                          completion: { _ in done() })
                    }

                    let request = httpRequestable.httpSessionMock.sentRequest
                    expect(request).toNot(beNil())
                    expect(request?.httpMethod).to(equal(HttpMethod.put.rawValue))
                }

                it("will send a request with provided data") {
                    let data = "data".data(using: .ascii)!
                    httpRequestable.bodyData = data
                    waitUntil { done in
                        httpRequestable.requestFromServer(url: URL(string: "https://test.url")!,
                                                          httpMethod: .put,
                                                          parameters: nil,
                                                          addtionalHeaders: nil,
                                                          completion: { _ in done() })
                    }

                    let request = httpRequestable.httpSessionMock.sentRequest
                    expect(request).toNot(beNil())
                    expect(request?.httpBody).to(equal(data))
                }

                it("will always send requests with application/json Content-Type header") {
                    waitUntil { done in
                        httpRequestable.requestFromServer(url: URL(string: "https://test.url")!,
                                                          httpMethod: .put,
                                                          parameters: nil,
                                                          addtionalHeaders: nil,
                                                          completion: { _ in done() })
                    }

                    let request = httpRequestable.httpSessionMock.sentRequest
                    expect(request).toNot(beNil())
                    expect(request?.allHTTPHeaderFields).to(equal(["Content-Type": "application/json"]))
                }

                it("will send a request with application/json Content-Type header along with other provided headers") {
                    let headers = [HeaderAttribute(key: "1", value: "abc"),
                                   HeaderAttribute(key: "a", value: "2")]
                    waitUntil { done in
                        httpRequestable.requestFromServer(url: URL(string: "https://test.url")!,
                                                          httpMethod: .put,
                                                          parameters: nil,
                                                          addtionalHeaders: headers,
                                                          completion: { _ in done() })
                    }

                    let request = httpRequestable.httpSessionMock.sentRequest
                    let headersDict = headers.reduce(into: ["Content-Type": "application/json"], { (acc, header) in
                        acc[header.key] = header.value
                    })
                    expect(request).toNot(beNil())
                    expect(request?.allHTTPHeaderFields).to(equal(headersDict))
                }

                it("will return an error if building body has failed") {
                    httpRequestable.bodyError = .bodyError

                    var result: HttpRequestable.RequestResult?
                    waitUntil { done in
                        httpRequestable.requestFromServer(
                            url: URL(string: "https://test.url")!,
                            httpMethod: .put,
                            parameters: nil,
                            addtionalHeaders: nil,
                            completion: { requestResult in
                                result = requestResult
                                done()
                        })
                    }

                    expect(result).toNot(beNil())
                    let error = result?.getError()
                    expect(error).to(matchError(RequestError.self))

                    guard case .bodyEncodingError(let enclosedError) = error,
                        let bodyError = enclosedError as? HttpRequestableObjectError,
                        case .bodyError = bodyError else {

                            fail("Unexpected error type \(String(describing: error)). Expected .bodyEncodingError(.bodyError)")
                            return
                    }
                }

                it("will return an error if session error occured") {
                    httpRequestable.httpSessionMock.responseError = HttpRequestableObjectError.sessionError

                    var result: HttpRequestable.RequestResult?
                    waitUntil { done in
                        httpRequestable.requestFromServer(
                            url: URL(string: "https://test.url")!,
                            httpMethod: .put,
                            parameters: nil,
                            addtionalHeaders: nil,
                            completion: { requestResult in
                                result = requestResult
                                done()
                        })
                    }

                    expect(result).toNot(beNil())
                    let error = result?.getError()
                    expect(error).to(matchError(RequestError.self))

                    guard case .taskFailed(let enclosedError) = error,
                        let sessionError = enclosedError as? HttpRequestableObjectError,
                        case .sessionError = sessionError else {

                            fail("Unexpected error type \(String(describing: error)). Expected .taskFailed(.sessionError)")
                            return
                    }
                }

                it("will return an error for code indicating an error <100, 300)") {
                    for code: UInt in [300, 400, 404, 422, 500, 501, 666] {

                        httpRequestable.httpSessionMock.responseData = "data".data(using: .ascii)!
                        httpRequestable.httpSessionMock.httpResponse = HTTPURLResponse(
                            url: URL(string: "https://test.url")!,
                            statusCode: Int(code),
                            httpVersion: nil,
                            headerFields: nil)

                        var result: HttpRequestable.RequestResult?
                        waitUntil { done in
                            httpRequestable.requestFromServer(
                                url: URL(string: "https://test.url")!,
                                httpMethod: .put,
                                parameters: nil,
                                addtionalHeaders: nil,
                                completion: { requestResult in
                                    result = requestResult
                                    done()
                            })
                        }

                        expect(result).toNot(beNil())
                        let error = result?.getError()
                        expect(error).to(matchError(RequestError.self))

                        guard case .httpError(let statusCode, _, _) = error else {
                            fail("Unexpected error type \(String(describing: error)). Expected .httpError")
                            return
                        }

                        expect(statusCode).to(equal(code))
                    }
                }

                it("will return an error if no response was returned") {
                    httpRequestable.httpSessionMock.responseData = "data".data(using: .ascii)!
                    httpRequestable.httpSessionMock.httpResponse = nil

                    var result: HttpRequestable.RequestResult?
                    waitUntil { done in
                        httpRequestable.requestFromServer(
                            url: URL(string: "https://test.url")!,
                            httpMethod: .put,
                            parameters: nil,
                            addtionalHeaders: nil,
                            completion: { requestResult in
                                result = requestResult
                                done()
                        })
                    }

                    expect(result).toNot(beNil())
                    let error = result?.getError()
                    expect(error).to(matchError(RequestError.self))

                    guard case .httpError = error else {
                        fail("Unexpected error type \(String(describing: error)). Expected .httpError")
                        return
                    }
                }

                it("will return an error if no data was returned") {
                    httpRequestable.httpSessionMock.responseData = nil
                    httpRequestable.httpSessionMock.httpResponse = HTTPURLResponse(
                        url: URL(string: "https://test.url")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil)

                    var result: HttpRequestable.RequestResult?
                    waitUntil { done in
                        httpRequestable.requestFromServer(
                            url: URL(string: "https://test.url")!,
                            httpMethod: .put,
                            parameters: nil,
                            addtionalHeaders: nil,
                            completion: { requestResult in
                                result = requestResult
                                done()
                        })
                    }

                    expect(result).toNot(beNil())
                    let error = result?.getError()
                    expect(error).to(matchError(RequestError.self))

                    guard case .httpError = error else {
                        fail("Unexpected error type \(String(describing: error)). Expected .httpError")
                        return
                    }
                }

                it("will return success if data is present and response contains valid code") {
                    for code in [100, 200, 201] {

                        httpRequestable.httpSessionMock.responseData = "data".data(using: .ascii)!
                        httpRequestable.httpSessionMock.httpResponse = HTTPURLResponse(
                            url: URL(string: "https://test.url")!,
                            statusCode: code,
                            httpVersion: nil,
                            headerFields: nil)

                        var result: HttpRequestable.RequestResult?
                        waitUntil { done in
                            httpRequestable.requestFromServer(
                                url: URL(string: "https://test.url")!,
                                httpMethod: .put,
                                parameters: nil,
                                addtionalHeaders: nil,
                                completion: { requestResult in
                                    result = requestResult
                                    done()
                            })
                        }

                        expect(result).toNot(beNil())
                        expect {
                            try result?.get()
                        }.toNot(throwError())
                    }
                }

                it("will return response and data objects when call succeeded") {
                    let data = "data".data(using: .ascii)!
                    let response = HTTPURLResponse(
                        url: URL(string: "https://test.url")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil)

                    httpRequestable.httpSessionMock.responseData = data
                    httpRequestable.httpSessionMock.httpResponse = response

                    var result: HttpRequestable.RequestResult?
                    waitUntil { done in
                        httpRequestable.requestFromServer(
                            url: URL(string: "https://test.url")!,
                            httpMethod: .put,
                            parameters: nil,
                            addtionalHeaders: nil,
                            completion: { requestResult in
                                result = requestResult
                                done()
                        })
                    }

                    let resultData = try? result?.get()
                    expect(resultData).toNot(beNil())
                    expect(resultData?.data).to(equal(data))
                    expect(resultData?.response).to(equal(response))
                }
            }
        }
    }
}

enum HttpRequestableObjectError: Error {
    case bodyError
    case sessionError
}

private class HttpRequestableObject: HttpRequestable {
    private(set) var httpSession: URLSession = URLSessionMock.mock(originalInstance: .shared)
    var httpSessionMock: URLSessionMock {
        // swiftlint:disable:next force_cast
        return httpSession as! URLSessionMock
    }
    var bodyError: HttpRequestableObjectError?
    var bodyData = Data()
    private(set) var passedParameters: [String: Any]?

    func buildHttpBody(with parameters: [String: Any]?) -> Result<Data, Error> {
        passedParameters = parameters
        if let error = bodyError {
            return .failure(error)
        } else {
            return .success(bodyData)
        }
    }
}
