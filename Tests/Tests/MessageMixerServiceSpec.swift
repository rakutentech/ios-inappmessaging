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

class MessageMixerServiceSpec: QuickSpec {

    override func spec() {

        let requestQueue = DispatchQueue(label: "iam.test.request")
        let configData = ConfigEndpointData(rolloutPercentage: 100, endpoints: .empty)
        let moduleConfig = InAppMessagingModuleConfiguration(configURLString: "https://config.url",
                                                             subscriptionID: "sub-id",
                                                             isTooltipFeatureEnabled: true)
        let accountRepository = AccountRepository(userDataCache: UserDataCacheMock())
        let userInfoProvider = UserInfoProviderMock()
        accountRepository.setPreference(userInfoProvider)

        var service: MessageMixerService!
        var configurationRepository: ConfigurationRepository!
        var httpSession: URLSessionMock!
        var eventLogger: MockEventLoggerSendable!
        var constants = Constants.IAMErrorCode.self

        func sendRequestAndWaitForResponse() {
            waitUntil { done in
                requestQueue.async {
                    _ = service.ping()
                    done()
                }
            }
        }

        describe("MessageMixerService") {

            beforeEach {
                URLSessionMock.startMockingURLSession()

                userInfoProvider.clear()
                configurationRepository = ConfigurationRepository()
                configurationRepository.saveRemoteConfiguration(configData)
                configurationRepository.saveIAMModuleConfiguration(moduleConfig)
                eventLogger = MockEventLoggerSendable()
                service = MessageMixerService(accountRepository: accountRepository,
                                              configurationRepository: configurationRepository,
                                              eventLogger: eventLogger)
                httpSession = URLSessionMock.mock(originalInstance: service.httpSession)
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()
            }

            context("when request succeeds") {

                beforeEach {
                    httpSession.httpResponse = HTTPURLResponse(url: configData.endpoints!.ping!,
                                                               statusCode: 200,
                                                               httpVersion: nil,
                                                               headerFields: nil)
                }

                context("and payload is valid") {

                    it("will return a valid data model") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "ping_success")

                        var pingResponse: PingResponse?
                        waitUntil { done in
                            requestQueue.async {
                                let result = service.ping()
                                expect {
                                    pingResponse = try result.get()
                                }.toNot(throwError())
                                done()
                            }
                        }
                        expect(pingResponse?.data).toNot(beEmpty())
                    }

                    it("will return a valid data model for payload with empty campaign list") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "ping_success_empty")

                        var pingResponse: PingResponse?
                        waitUntil { done in
                            requestQueue.async {
                                let result = service.ping()
                                expect {
                                    pingResponse = try result.get()
                                }.toNot(throwError())
                                done()
                            }
                        }
                        expect(pingResponse).toNot(beNil())
                        expect(pingResponse?.data).to(beEmpty())
                    }
                }

                context("and payload is not valid") {

                    it("will return .jsonDecodingError payload is invalid") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "ping_invalid")

                        waitUntil { done in
                            requestQueue.async {
                                let result = service.ping()
                                let error = result.getError()
                                expect(error).toNot(beNil())

                                guard case .jsonDecodingError = error else {
                                    fail("Unexpected error type \(String(describing: error)). Expected .requestError")
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

                it("will return MessageMixerServiceError containing .requestError") {
                    httpSession.responseError = NSError(domain: "config.error.test", code: 1, userInfo: nil)

                    waitUntil { done in
                        requestQueue.async {
                            let result = service.ping()
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

                context("and the status code equals to 429") {
                    it("will return MessageMixerServiceError containig .tooManyRequestsError") {
                        httpSession.httpResponse = HTTPURLResponse(url: URL(string: "https://ping.url")!,
                                                                   statusCode: 429,
                                                                   httpVersion: nil,
                                                                   headerFields: nil)

                        waitUntil { done in
                            requestQueue.async {
                                let result = service.ping()
                                let error = result.getError()
                                expect(error).toNot(beNil())

                                expect(eventLogger.logEventCalled).to(beTrue())
                                expect(eventLogger.lastEventType).to(equal(REventType.critical))
                                expect(eventLogger.lastErrorCode).to(equal(constants.pingTooManyRequestsError.errorCode + "429"))
                                expect(eventLogger.lastErrorMessage).to(equal(constants.pingTooManyRequestsError.errorMessage))

                                guard case .tooManyRequestsError = error else {
                                    fail("Unexpected error type \(String(describing: error)). Expected .tooManyRequestsError")
                                    done()
                                    return
                                }
                                done()
                            }
                        }
                    }
                }

                context("and the status code equals to 4xx") {
                    for code in [400, 401, 422] {
                        it("will return MessageMixerServiceError containig .invalidRequestError with \(code) value") {
                            httpSession.httpResponse = HTTPURLResponse(url: URL(string: "https://ping.url")!,
                                                                       statusCode: code,
                                                                       httpVersion: nil,
                                                                       headerFields: nil)

                            waitUntil { done in
                                requestQueue.async {
                                    let result = service.ping()
                                    let error = result.getError()
                                    expect(error).toNot(beNil())

                                    expect(eventLogger.logEventCalled).to(beTrue())
                                    expect(eventLogger.lastEventType).to(equal(REventType.critical))
                                    let errorCodeParts = eventLogger.lastErrorCode?.components(separatedBy: ":")
                                    expect(Int(errorCodeParts?[1] ?? " ")).to(beGreaterThanOrEqualTo(300))
                                    expect(Int(errorCodeParts?[1] ?? " ")).to(beLessThan(500))
                                    expect((errorCodeParts?[0])!+":").to(equal(constants.pingInvalidRequestError.errorCode))
                                    expect(eventLogger.lastErrorMessage).to(equal(constants.pingInvalidRequestError.errorMessage))

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
                        it("will return MessageMixerServiceError containig .internalServerError with \(code) value") {
                            httpSession.httpResponse = HTTPURLResponse(url: URL(string: "https://ping.url")!,
                                                                       statusCode: code,
                                                                       httpVersion: nil,
                                                                       headerFields: nil)

                            waitUntil { done in
                                requestQueue.async {
                                    let result = service.ping()
                                    let error = result.getError()
                                    expect(error).toNot(beNil())

                                    expect(eventLogger.lastEventType).to(equal(REventType.critical))
                                    let errorCodeParts = eventLogger.lastErrorCode?.components(separatedBy: ":")
                                    expect(Int(errorCodeParts?[1] ?? " ")).to(beGreaterThanOrEqualTo(500))
                                    expect((errorCodeParts?[0])!+":").to(equal(constants.pingInternalServerError.errorCode))
                                    expect(eventLogger.lastErrorMessage).to(equal(constants.pingInternalServerError.errorMessage))

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

                context("configuration doesn't have valid ping endpoint") {
                    it("will return invalid configuration error") {
                        waitUntil { done in
                            let configData = ConfigEndpointData(rolloutPercentage: 100, endpoints: .invalid)
                            configurationRepository.saveRemoteConfiguration(configData)
                            let result = service.ping()
                            let error = result.getError()
                            expect(error).toNot(beNil())
                            guard case .invalidConfiguration = error else {
                                fail("Unexpected error type \(String(describing: error)). Expected .invalidConfiguration")
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

                it("will use ping URL from config data") {
                    sendRequestAndWaitForResponse()
                    expect(httpSession.sentRequest).toNot(beNil())
                    expect(httpSession.sentRequest?.url).to(equal(configData.endpoints?.ping))
                }

                context("when rmc sdk is integrated") {
                    it("will send a valid data object and will contain rmcSdk version") {
                        sendRequestAndWaitForResponse()

                        let request = httpSession.decodeSentData(modelType: PingRequest.self)
                        expect(request).toNot(beNil())
                        expect(request?.appVersion).to(equal(BundleInfoMock.appVersion))
                        expect(request?.supportedCampaignTypes).to(elementsEqualOrderAgnostic([.regular, .pushPrimer]))
                        expect(request?.rmcSdkVersion).to(equal(BundleInfoMock.rmcSdkVersion))
                    }
                }

                context("when rmc sdk is not integrated") {
                    it("will send a valid data object and not contain rmcSdk version") {
                        BundleInfoMock.rmcSdkVersionMock = nil
                        sendRequestAndWaitForResponse()

                        let request = httpSession.decodeSentData(modelType: PingRequest.self)
                        expect(request).toNot(beNil())
                        expect(request?.appVersion).to(equal(BundleInfoMock.appVersion))
                        expect(request?.supportedCampaignTypes).to(elementsEqualOrderAgnostic([.regular, .pushPrimer]))
                        expect(request?.rmcSdkVersion).to(beNil())
                    }
                }

                it("will send user preferences in the request") {
                    userInfoProvider.userID = "userId"
                    userInfoProvider.idTrackingIdentifier = "tracking-id"

                    sendRequestAndWaitForResponse()

                    let request = httpSession.decodeSentData(modelType: PingRequest.self)

                    expect(request?.userIdentifiers).to(elementsEqualOrderAgnostic([
                        UserIdentifier(type: .idTrackingIdentifier, identifier: "tracking-id"),
                        UserIdentifier(type: .userId, identifier: "userId")]))
                }

                it("will send required headers") {
                    userInfoProvider.accessToken = "token"

                    sendRequestAndWaitForResponse()

                    let Keys = Constants.Request.Header.self
                    let headers = httpSession.sentRequest?.allHTTPHeaderFields
                    expect(headers).toNot(beEmpty())
                    expect(headers?[Keys.subscriptionID]).to(equal(configurationRepository.getSubscriptionID()))
                    expect(headers?[Keys.deviceID]).toNot(beEmpty())
                    expect(headers?[Keys.authorization]).to(equal("OAuth2 token"))
                }

                context("and required data is missing") {

                    it("will return RequestError.missingMetadata error if host app version is missing") {
                        BundleInfoMock.appVersionMock = nil

                        waitUntil { done in
                            requestQueue.async {
                                let result = service.ping()
                                let error = result.getError()
                                expect(error).toNot(beNil())

                                guard case .requestError(let requestError) = error,
                                      case .bodyEncodingError(let enclosedError) = requestError,
                                      case .missingMetadata = enclosedError as? RequestError else {
                                    fail("Unexpected error type \(String(describing: error)). Expected .requestError(.missingMetadata)")
                                    done()
                                    return
                                }
                                done()
                            }
                        }
                    }
                }
            }
        }
    }
}
