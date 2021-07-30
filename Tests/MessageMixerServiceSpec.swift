import Quick
import Nimble
@testable import RInAppMessaging

class MessageMixerServiceSpec: QuickSpec {

    override func spec() {

        let requestQueue = DispatchQueue(label: "iam.test.request")
        let configData = ConfigData(rolloutPercentage: 100, endpoints: .empty)

        var service: MessageMixerService!
        var preferenceRepository: AccountRepository!
        var configurationRepository: ConfigurationRepository!
        var httpSession: URLSessionMock!

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

                preferenceRepository = AccountRepository()
                configurationRepository = ConfigurationRepository()
                configurationRepository.saveConfiguration(configData)
                service = MessageMixerService(preferenceRepository: preferenceRepository,
                                              configurationRepository: configurationRepository)
                httpSession = URLSessionMock.mock(originalInstance: service.httpSession)
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()
            }

            it("will use provided URL in a request") {
                sendRequestAndWaitForResponse()
                expect(httpSession.sentRequest).toNot(beNil())
                expect(httpSession.sentRequest?.url).to(equal(configData.endpoints?.ping))
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
                beforeEach {
                    httpSession.responseError = NSError(domain: "config.error.test", code: 1, userInfo: nil)
                }

                it("will return ConfigurationServiceError containing .requestError") {
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
            }

            context("when request fails with a status code equals to 429") {
                let originalHttpResponse: HTTPURLResponse? = httpSession?.httpResponse

                it("will return ConfigurationServiceError containig .tooManyRequestsError") {
                    httpSession.httpResponse = HTTPURLResponse(url: URL(string: "https://ping.url")!,
                                                               statusCode: 429,
                                                               httpVersion: nil,
                                                               headerFields: nil)

                    waitUntil { done in
                        requestQueue.async {
                            let result = service.ping()
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

                afterEach {
                    httpSession.httpResponse = originalHttpResponse
                }
            }

            context("when making a request") {
                beforeEach {
                    BundleInfoMock.reset()
                    service.bundleInfo = BundleInfoMock.self
                }

                it("will send a valid data object") {
                    sendRequestAndWaitForResponse()

                    let request = httpSession.decodeSentData(modelType: PingRequest.self)

                    expect(request).toNot(beNil())
                    expect(request?.appVersion).to(equal(BundleInfoMock.appVersion))
                }

                it("will send user preferences in the request") {
                    preferenceRepository.setPreference(UserInfoProviderMock(userID: "userId", rakutenId: "rakutenId"))

                    sendRequestAndWaitForResponse()

                    let request = httpSession.decodeSentData(modelType: PingRequest.self)

                    expect(request?.userIdentifiers).to(equal([
                        UserIdentifier(type: .rakutenId, identifier: "rakutenId"),
                        UserIdentifier(type: .userId, identifier: "userId")]))
                }

                it("will send required headers") {
                    preferenceRepository.setPreference(UserInfoProviderMock(authToken: "token"))

                    sendRequestAndWaitForResponse()

                    let Keys = Constants.Request.Header.self
                    let headers = httpSession.sentRequest?.allHTTPHeaderFields
                    expect(headers).toNot(beEmpty())
                    expect(headers?[Keys.subscriptionID]).to(equal(BundleInfoMock.inAppSubscriptionId))
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
