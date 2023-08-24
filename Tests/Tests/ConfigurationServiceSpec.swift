import Foundation
import Quick
import Nimble

#if canImport(RSDKUtilsTestHelpers)
import class RSDKUtilsTestHelpers.URLSessionMock // SPM version
#else
import class RSDKUtils.URLSessionMock
#endif

@testable import RInAppMessaging

private let configURL = URL(string: "http://config.url")!

class ConfigurationServiceSpec: QuickSpec {

    override func spec() {

        let requestQueue = DispatchQueue(label: "iam.test.request")
        let moduleConfig = InAppMessagingModuleConfiguration(configURLString: configURL.absoluteString,
                                                             subscriptionID: "sub-id",
                                                             isTooltipFeatureEnabled: true)

        var service: ConfigurationService!
        var httpSession: URLSessionMock!
        var configRepository: ConfigurationRepository!

        describe("ConfigurationService") {

            beforeEach {
                URLSessionMock.startMockingURLSession()

                configRepository = ConfigurationRepository()
                configRepository.saveIAMModuleConfiguration(moduleConfig)
                service = ConfigurationService(configurationRepository: configRepository)

                BundleInfoMock.reset()
                service.bundleInfo = BundleInfoMock.self

                httpSession = URLSessionMock.mock(originalInstance: service.httpSession)
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()
            }

            context("when request succeeds") {

                beforeEach {
                    httpSession.httpResponse = ConfigURLResponse(statusCode: 200)
                }

                context("and payload is valid") {

                    var configModel: ConfigEndpointData?

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

                        expect(configModel?.endpoints?.ping)
                            .to(equal(URL( string: "https://endpoint.com/ping")!))
                    }

                    it("will return a valid data model containing impression URL") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "config_success")
                        fetchConfig()

                        expect(configModel?.endpoints?.impression)
                            .to(equal(URL( string: "https://endpoint.com/impression")!))
                    }

                    it("will return a valid data model containing displayPermission URL") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "config_success")
                        fetchConfig()

                        expect(configModel?.endpoints?.displayPermission)
                            .to(equal(URL( string: "https://endpoint.com/display_permission")!))
                    }

                    it("will return a valid data model for payload without optional values") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "config_success_optional")
                        fetchConfig()

                        expect(configModel).toNot(beNil())
                        expect(configModel?.endpoints).to(beNil())
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
                }

                context("and status code is 4xx") {

                    it("will return ConfigurationServiceError containing .tooManyRequestsError for code 429") {
                        httpSession.httpResponse = ConfigURLResponse(statusCode: 429)
                        waitUntil { done in
                            requestQueue.async {
                                let result = service.getConfigData()
                                let error = result.getError()
                                expect(error).toNot(beNil())

                                guard case .tooManyRequestsError = error else {
                                    fail("Unexpected error type \(String(describing: error)). Expected .tooManyRequestsError")
                                    done()
                                    return
                                }
                                done()
                            }
                        }
                    }

                    it("will return ConfigurationServiceError containing .missingOrInvalidSubscriptionId for code 400") {
                        httpSession.httpResponse = ConfigURLResponse(statusCode: 400)
                        waitUntil { done in
                            requestQueue.async {
                                let result = service.getConfigData()
                                let error = result.getError()
                                expect(error).toNot(beNil())

                                guard case .missingOrInvalidSubscriptionId = error else {
                                    fail("Unexpected error type \(String(describing: error)). Expected .missingOrInvalidSubscriptionId")
                                    done()
                                    return
                                }
                                done()
                            }
                        }
                    }

                    it("will return ConfigurationServiceError containing .unknownSubscriptionId for code 404") {
                        httpSession.httpResponse = ConfigURLResponse(statusCode: 404)
                        waitUntil { done in
                            requestQueue.async {
                                let result = service.getConfigData()
                                let error = result.getError()
                                expect(error).toNot(beNil())

                                guard case .unknownSubscriptionId = error else {
                                    fail("Unexpected error type \(String(describing: error)). Expected .missingOrInvalidSubscriptionId")
                                    done()
                                    return
                                }
                                done()
                            }
                        }
                    }

                    for code in [401, 403, 422] {
                        it("will return ConfigurationServiceError containig .invalidRequestError with \(code) value") {
                            httpSession.httpResponse = ConfigURLResponse(statusCode: code)

                            waitUntil { done in
                                requestQueue.async {
                                    let result = service.getConfigData()
                                    let error = result.getError()
                                    expect(error).toNot(beNil())

                                    guard case .invalidRequestError(let code) = error else {
                                        fail("Unexpected error type \(String(describing: error)). Expected .invalidRequestError")
                                        done()
                                        return
                                    }
                                    expect(code).to(equal(code))
                                    done()
                                }
                            }
                        }
                    }
                }

                context("and the status code equals to 5xx") {
                    for code in [500, 501, 520] {
                        it("will return ConfigurationServiceError containig .internalServerError with \(code) value") {
                            httpSession.httpResponse = ConfigURLResponse(statusCode: code)

                            waitUntil { done in
                                requestQueue.async {
                                    let result = service.getConfigData()
                                    let error = result.getError()
                                    expect(error).toNot(beNil())

                                    guard case .internalServerError(let code) = error else {
                                        fail("Unexpected error type \(String(describing: error)). Expected .internalServerError")
                                        done()
                                        return
                                    }
                                    expect(code).to(equal(code))
                                    done()
                                }
                            }
                        }
                    }
                }
            }

            context("when request fails") {
                beforeEach {
                    httpSession.responseError = NSError(domain: "config.error.test", code: 1, userInfo: nil)
                }

                it("will return ConfigurationServiceError containing .requestError") {
                    httpSession.responseError = NSError(domain: "config.error.test", code: 1, userInfo: nil)

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

            context("when building request body") {

                it("will return RequestError.bodyIsNil with parameters") {
                    let result = service.buildHttpBody(with: ["key": "value"])
                    let error = result.getError() as? RequestError
                    expect(error).toNot(beNil())
                }

                it("will return RequestError.bodyIsNil when parameters is nil") {
                    let result = service.buildHttpBody(with: nil)
                    let error = result.getError() as? RequestError
                    expect(error).toNot(beNil())
                }
            }

            context("when making a request") {
                beforeEach {
                    BundleInfoMock.reset()
                    service.bundleInfo = BundleInfoMock.self
                }

                it("will use provided URL in a request") {
                    waitUntil { done in
                        requestQueue.async {
                            _ = service.getConfigData()
                            done()
                        }
                    }
                    expect(httpSession.sentRequest?.url?.scheme).to(equal(configURL.scheme))
                    expect(httpSession.sentRequest?.url?.host).to(equal(configURL.host))
                }

                it("will send a valid data object when rmcSdk is integrated") {
                    waitUntil { done in
                        requestQueue.async {
                            _ = service.getConfigData()
                            done()
                        }
                    }

                    let request = httpSession.decodeQueryItems(modelType: GetConfigRequest.self)

                    expect(request).toNot(beNil())
                    expect(request?.locale).to(equal(Locale.current.normalizedIdentifier))
                    expect(request?.appVersion).to(equal(BundleInfoMock.appVersion))
                    expect(request?.platform).to(equal(.ios))
                    expect(request?.appId).to(equal(BundleInfoMock.applicationId))
                    expect(request?.sdkVersion).to(equal(Constants.Versions.sdkVersion))
                    expect(request?.rmcSdkVersion).to(equal(BundleInfoMock.rmcSdkVersion))
                }
                it("will send a valid data object when rmcSdk is not integrated") {
                    BundleInfoMock.rmcSdkVersionMock = nil
                    waitUntil { done in
                        requestQueue.async {
                            _ = service.getConfigData()
                            done()
                        }
                    }

                    let request = httpSession.decodeQueryItems(modelType: GetConfigRequest.self)

                    expect(request).toNot(beNil())
                    expect(request?.locale).to(equal(Locale.current.normalizedIdentifier))
                    expect(request?.appVersion).to(equal(BundleInfoMock.appVersion))
                    expect(request?.platform).to(equal(.ios))
                    expect(request?.appId).to(equal(BundleInfoMock.applicationId))
                    expect(request?.sdkVersion).to(equal(Constants.Versions.sdkVersion))
                    expect(request?.rmcSdkVersion).to(beNil())
                }

                it("will send subscription id in header") {
                    waitUntil { done in
                        requestQueue.async {
                            _ = service.getConfigData()
                            done()
                        }
                    }

                    let Keys = Constants.Request.Header.self
                    let headers = httpSession.sentRequest?.allHTTPHeaderFields
                    expect(headers).toNot(beEmpty())
                    expect(headers?[Keys.subscriptionID]).to(equal(configRepository.getSubscriptionID()))
                }

                context("and required data is missing") {

                    func makeRequestAndEvaluateMetadataError() {
                        waitUntil { done in
                            requestQueue.async {
                                let result = service.getConfigData()
                                let error = result.getError()
                                expect(error).toNot(beNil())

                                guard case .requestError(let requestError) = error,
                                      case .urlBuildingError(let encodingError) = requestError,
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
                        makeRequestAndEvaluateMetadataError()
                    }

                    it("will return RequestError.missingMetadata error if host app version is missing") {
                        BundleInfoMock.appVersionMock = nil
                        makeRequestAndEvaluateMetadataError()
                    }

                    it("will throwAssertion when SubscriptionID is missing") {
                        configRepository.saveIAMModuleConfiguration(InAppMessagingModuleConfiguration(configURLString: "http:config.url",
                                                                                                      subscriptionID: nil,
                                                                                                      isTooltipFeatureEnabled: true))
                        waitUntil { done in
                            requestQueue.async {
                                expect(service.getConfigData()).to(throwAssertion())
                                done()
                            }
                        }
                    }
                }
                context("and config url is invalid") {

                    func makeRequestAndValidateError() {
                        waitUntil { done in
                            requestQueue.async {
                                let result = service.getConfigData()
                                let error = result.getError()
                                expect(error).toNot(beNil())

                                guard case .missingOrInvalidConfigURL = error else {
                                    fail("Unexpected error type \(String(describing: error)). Expected .missingOrInvalidConfigURL")
                                    done()
                                    return
                                }
                                done()
                            }
                        }
                    }

                    it("will return error if configURL is nil") {
                        configRepository.saveIAMModuleConfiguration(InAppMessagingModuleConfiguration(configURLString: nil,
                                                                                                      subscriptionID: "sub-id",
                                                                                                      isTooltipFeatureEnabled: true))
                        makeRequestAndValidateError()
                    }

                    it("will return error if configURL is empty") {
                        configRepository.saveIAMModuleConfiguration(InAppMessagingModuleConfiguration(configURLString: "",
                                                                                                      subscriptionID: "sub-id",
                                                                                                      isTooltipFeatureEnabled: true))
                        makeRequestAndValidateError()
                    }
                }
            }
        }
    }
}

private class ConfigURLResponse: HTTPURLResponse {
    init?(statusCode: Int) {
        super.init(url: configURL,
                   statusCode: statusCode,
                   httpVersion: nil,
                   headerFields: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
