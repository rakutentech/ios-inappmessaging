import Quick
import Nimble
@testable import RInAppMessaging

class ConfigurationServiceSpec: QuickSpec {

    override func spec() {

        let requestQueue = DispatchQueue(label: "iam.test.request")
        let configURL = URL(string: "http://config.url")!

        var service: ConfigurationService!
        var httpSession: URLSessionMock!

        describe("ConfigurationService") {

            beforeEach {
                URLSessionMock.startMockingURLSession()

                service = ConfigurationService(configURL: configURL,
                                               sessionConfiguration: .default)
                httpSession = URLSessionMock.mock(originalInstance: service.httpSession)
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()
            }

            it("will use provided URL in a request") {
                waitUntil { done in
                    requestQueue.async {
                        _ = service.getConfigData()
                        done()
                    }
                }
                expect(httpSession.sentRequest?.url).to(equal(configURL))
            }

            context("when request succeeds") {

                beforeEach {
                    httpSession.httpResponse = HTTPURLResponse(url: configURL,
                                                               statusCode: 200,
                                                               httpVersion: nil,
                                                               headerFields: nil)
                }

                context("and payload is valid") {

                    var configModel: ConfigData?

                    beforeEach {
                        configModel = nil
                    }

                    func fetchConfig() {
                        waitUntil { done in
                            requestQueue.async {
                                let result = service.getConfigData()
                                expect {
                                    configModel = try result.get()
                                }.toNot(throwError())
                                done()
                            }
                        }
                    }

                    it("will return a valid data model containing ping URL") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "config_success")
                        fetchConfig()

                        expect(configModel?.endpoints.ping)
                            .to(equal(URL( string: "https://endpoint.com/ping")!))
                    }

                    it("will return a valid data model containing impression URL") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "config_success")
                        fetchConfig()

                        expect(configModel?.endpoints.impression)
                            .to(equal(URL( string: "https://endpoint.com/impression")!))
                    }

                    it("will return a valid data model containing displayPermission URL") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "config_success")
                        fetchConfig()

                        expect(configModel?.endpoints.displayPermission)
                            .to(equal(URL( string: "https://endpoint.com/display_permission")!))
                    }

                    it("will return a valid data model for payload without optional values") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "config_success_optional")
                        fetchConfig()

                        expect(configModel?.endpoints.ping)
                            .to(equal(URL( string: "https://endpoint.com/ping")!))
                    }
                }

                context("and payload is not valid") {

                    it("will return .jsonDecodingError when `enabled` is missing") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "config_fail_enabled")

                        waitUntil { done in
                            requestQueue.async {
                                let result = service.getConfigData()
                                let error = result.getError()
                                expect(error).toNot(beNil())

                                guard case .jsonDecodingError = error else {
                                    fail("Unexpected error type \(String(describing: error)). Expected .jsonDecodingError")
                                    done()
                                    return
                                }
                                done()
                            }
                        }
                    }

                    it("will return .jsonDecodingError when ping endpoint is missing") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "config_fail_ping")

                        waitUntil { done in
                            requestQueue.async {
                                let result = service.getConfigData()
                                let error = result.getError()
                                expect(error).toNot(beNil())

                                guard case .jsonDecodingError = error else {
                                    fail("Unexpected error type \(String(describing: error)). Expected .jsonDecodingError")
                                    done()
                                    return
                                }
                                done()
                            }
                        }
                    }
                }
            }

            context("when request fails") {
                beforeEach {
                    httpSession.responseError = NSError(domain: "config.error.test", code: 1, userInfo: nil)
                }

                it("will return ConfigurationServiceError containig RequestError") {
                    waitUntil { done in
                        requestQueue.async {
                            let result = service.getConfigData()
                            let error = result.getError()
                            expect(error).toNot(beNil())

                            guard case .requestError = error else {
                                fail("Unexpected error type \(String(describing: error)). Expected .requestError")
                                done()
                                return
                            }
                            done()
                        }
                    }
                }
            }

            context("when making a request") {
                beforeEach {
                    BundleInfoMock.reset()
                    service.bundleInfo = BundleInfoMock.self
                }

                it("will send a valid data object") {
                    waitUntil { done in
                        requestQueue.async {
                            _ = service.getConfigData()
                            done()
                        }
                    }

                    let request = httpSession.decodeSentData(modelType: GetConfigRequest.self)

                    expect(request).toNot(beNil())
                    expect(request?.locale).to(equal(Locale.current.normalizedIdentifier))
                    expect(request?.appVersion).to(equal(BundleInfoMock.appVersion))
                    expect(request?.platform).to(equal(.ios))
                    expect(request?.appId).to(equal(BundleInfoMock.applicationId))
                    expect(request?.sdkVersion).to(equal(BundleInfoMock.inAppSdkVersion))
                }

                context("and required data is missing") {

                    func makeRequestAndEvaluateError() {
                        waitUntil { done in
                            requestQueue.async {
                                let result = service.getConfigData()
                                let error = result.getError()
                                expect(error).toNot(beNil())

                                guard case .requestError(let requestError) = error,
                                      case .bodyEncodingError(let encodingError) = requestError,
                                      case .missingMetadata = encodingError as? RequestError else {
                                    fail("Unexpected error type \(String(describing: error)). Expected .requestError(.missingMetadata)")
                                    done()
                                    return
                                }
                                done()
                            }
                        }
                    }

                    it("will return RequestError.missingMetadata error if application id is missing") {
                        BundleInfoMock.applicationIdMock = nil
                        makeRequestAndEvaluateError()
                    }

                    it("will return RequestError.missingMetadata error if sdk version is missing") {
                        BundleInfoMock.inAppSdkVersionMock = nil
                        makeRequestAndEvaluateError()
                    }

                    it("will return RequestError.missingMetadata error if host app version is missing") {
                        BundleInfoMock.appVersionMock = nil
                        makeRequestAndEvaluateError()
                    }
                }
            }
        }
    }
}
