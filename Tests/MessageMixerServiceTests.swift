import Quick
import Nimble
@testable import RInAppMessaging

class MessageMixerServiceTests: QuickSpec {

    override func spec() {

        let requestQueue = DispatchQueue(label: "iam.test.request")
        let configData = ConfigData(enabled: true,
                                    endpoints: EndpointURL(
                                        ping: URL(string: "https://ping.url")!,
                                        displayPermission: nil,
                                        impression: nil))

        var service: MessageMixerService!
        var preferenceRepository: IAMPreferenceRepository!
        var configurationRepository: ConfigurationRepository!
        var httpSession: URLSessionMock!

        describe("MessageMixerService") {

            beforeEach {
                URLSessionMock.startMockingURLSession()

                preferenceRepository = IAMPreferenceRepository()
                configurationRepository = ConfigurationRepository()
                configurationRepository.saveConfiguration(configData)
                service = MessageMixerService(preferenceRepository: preferenceRepository,
                                              configurationRepository: configurationRepository)
                httpSession = URLSessionMock(originalInstance: service.httpSession)
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()
            }

            it("will use provided URL in a request") {
                waitUntil { done in
                    requestQueue.async {
                        _ = service.ping()
                        done()
                    }
                }
                expect(httpSession.sentRequest).toNot(beNil())
                expect(httpSession.sentRequest?.url).to(equal(configData.endpoints.ping))
            }

            context("when request succeeds") {

                beforeEach {
                    httpSession.httpResponse = HTTPURLResponse(url: configData.endpoints.ping,
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

                it("will return ConfigurationServiceError containig RequestError") {
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

            context("when making a request") {
                beforeEach {
                    service.bundleInfo = BundleInfoMock.self
                }

                it("will send a valid data object") {
                    waitUntil { done in
                        requestQueue.async {
                            _ = service.ping()
                            done()
                        }
                    }

                    let request = httpSession.decodeSentData(modelType: PingRequest.self)

                    expect(request).toNot(beNil())
                    expect(request?.appVersion).to(equal(BundleInfoMock.appVersion))
                }

                it("will send user preferences in the request") {
                    preferenceRepository.setPreference(IAMPreferenceBuilder()
                        .setRakutenId("rakutenId")
                        .setUserId("userId")
                        .build())

                    waitUntil { done in
                        requestQueue.async {
                            _ = service.ping()
                            done()
                        }
                    }

                    let request = httpSession.decodeSentData(modelType: PingRequest.self)

                    expect(request?.userIdentifiers).to(equal([
                        UserIdentifier(type: .rakutenId, identifier: "rakutenId"),
                        UserIdentifier(type: .userId, identifier: "userId")]))
                }

                it("will send required headers") {
                    preferenceRepository.setPreference(IAMPreferenceBuilder()
                        .setAccessToken("token")
                        .build())

                    waitUntil { done in
                        requestQueue.async {
                            _ = service.ping()
                            done()
                        }
                    }

                    let Keys = Constants.Request.Header.self
                    let headers = httpSession.sentRequest?.allHTTPHeaderFields
                    expect(headers).toNot(beEmpty())
                    expect(headers?[Keys.subscriptionID]).to(equal(BundleInfoMock.inAppSubscriptionId))
                    expect(headers?[Keys.deviceID]).toNot(beEmpty())
                    expect(headers?[Keys.authorization]).to(equal("OAuth2 token"))
                }
            }
        }
    }
}
