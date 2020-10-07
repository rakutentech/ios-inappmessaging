import Quick
import Nimble
@testable import RInAppMessaging

class ImpressionServiceTests: QuickSpec {

    override func spec() {

        let requestQueue = DispatchQueue(label: "iam.test.request")
        let configData = ConfigData(enabled: true,
                                    endpoints: EndpointURL(
                                        ping: URL(string: "https://ping.url")!,
                                        displayPermission: nil,
                                        impression: URL(string: "https://impression.url")!))
        let campaign = TestHelpers.generateCampaign(id: "test")

        var service: ImpressionService!
        var preferenceRepository: IAMPreferenceRepository!
        var configurationRepository: ConfigurationRepository!
        var httpSession: URLSessionMock!
        var errorDelegate: ErrorDelegateMock!

        describe("ImpressionService") {

            beforeEach {
                URLSessionMock.startMockingURLSession()

                preferenceRepository = IAMPreferenceRepository()
                configurationRepository = ConfigurationRepository()
                configurationRepository.saveConfiguration(configData)
                errorDelegate = ErrorDelegateMock()
                service = ImpressionService(preferenceRepository: preferenceRepository,
                                            configurationRepository: configurationRepository)
                service.errorDelegate = errorDelegate
                httpSession = URLSessionMock(originalInstance: service.httpSession)
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()
            }

            it("will use provided URL in a request") {
                waitUntil { done in
                    requestQueue.async {
                        service.pingImpression(impressions: [], campaignData: campaign.data)
                        done()
                    }
                }
                expect(httpSession.sentRequest).toNot(beNil())
                expect(httpSession.sentRequest?.url).to(equal(configData.endpoints.impression))
            }

            it("will report an error if url is not available") {
                configurationRepository.saveConfiguration(
                    ConfigData(enabled: true,
                               endpoints: EndpointURL(
                                ping: URL(string: "https://ping.url")!,
                                displayPermission: nil,
                                impression: nil)))

                waitUntil { done in
                    requestQueue.async {
                        service.pingImpression(impressions: [], campaignData: campaign.data)
                        done()
                    }
                }
                expect(errorDelegate.wasErrorReceived).toEventually(beTrue())
            }

            context("when request succeeds") {

                beforeEach {
                    httpSession.httpResponse = HTTPURLResponse(url: configData.endpoints.impression!,
                                                               statusCode: 200,
                                                               httpVersion: nil,
                                                               headerFields: nil)
                    httpSession.responseData = Data()
                }

                it("will not report any error") {
                    waitUntil { done in
                        requestQueue.async {
                            service.pingImpression(impressions: [], campaignData: campaign.data)
                            done()
                        }
                    }
                    expect(errorDelegate.wasErrorReceived).toAfterTimeout(beFalse())
                }
            }

            context("when request fails") {
                beforeEach {
                    httpSession.responseError = NSError(domain: "config.error.test", code: 1, userInfo: nil)
                }

                it("will report an error") {
                    waitUntil { done in
                        requestQueue.async {
                            service.pingImpression(impressions: [], campaignData: campaign.data)
                            done()
                        }
                    }
                    expect(errorDelegate.wasErrorReceived).toEventually(beTrue())
                }
            }

            context("when making a request") {
                beforeEach {
                    service.bundleInfo = BundleInfoMock.self
                }

                it("will send a valid data object") {
                    waitUntil { done in
                        requestQueue.async {
                            service.pingImpression(impressions: [], campaignData: campaign.data)
                            done()
                        }
                    }

                    expect(httpSession.decodeSentData(modelType: ImpressionRequest.self))
                        .toEventuallyNot(beNil())
                    let request = httpSession.decodeSentData(modelType: ImpressionRequest.self)
                    expect(request?.campaignId).to(equal(campaign.id))
                    expect(request?.appVersion).to(equal(BundleInfoMock.appVersion))
                    expect(request?.sdkVersion).to(equal(BundleInfoMock.inAppSdkVersion))
                }

                it("will send impressions in the request") {
                    let impressions = [Impression(type: .actionOne, timestamp: 10),
                                       Impression(type: .exit, timestamp: 2)]
                    waitUntil { done in
                        requestQueue.async {
                            service.pingImpression(impressions: impressions, campaignData: campaign.data)
                            done()
                        }
                    }

                    expect(httpSession.decodeSentData(modelType: ImpressionRequest.self))
                        .toEventuallyNot(beNil())
                    let request = httpSession.decodeSentData(modelType: ImpressionRequest.self)
                    expect(request?.impressions).to(equal(impressions))
                }

                it("will send user preferences in the request") {
                    preferenceRepository.setPreference(IAMPreferenceBuilder()
                        .setRakutenId("rakutenId")
                        .setUserId("userId")
                        .build())

                    waitUntil { done in
                        requestQueue.async {
                            service.pingImpression(impressions: [], campaignData: campaign.data)
                            done()
                        }
                    }

                    expect(httpSession.decodeSentData(modelType: ImpressionRequest.self))
                        .toEventuallyNot(beNil())
                    let request = httpSession.decodeSentData(modelType: ImpressionRequest.self)
                    expect(request?.userIdentifiers).to(equal([
                        UserIdentifier(type: .rakutenId, identifier: "rakutenId"),
                        UserIdentifier(type: .userId, identifier: "userId")]))
                }

                it("will send required headers") {
                    preferenceRepository.setPreference(IAMPreferenceBuilder()
                        .setAccessToken("rae-token")
                        .build())

                    waitUntil { done in
                        requestQueue.async {
                            service.pingImpression(impressions: [], campaignData: campaign.data)
                            done()
                        }
                    }

                    let Keys = Constants.Request.Header.self
                    expect(httpSession.sentRequest?.allHTTPHeaderFields).toEventuallyNot(beEmpty())
                    let headers = httpSession.sentRequest?.allHTTPHeaderFields
                    expect(headers?[Keys.subscriptionID]).to(equal(BundleInfoMock.inAppSubscriptionId))
                    expect(headers?[Keys.deviceID]).toNot(beEmpty())
                    expect(headers?[Keys.authorization]).to(equal("OAuth2 rae-token"))
                }
            }
        }
    }
}

private class ErrorDelegateMock: ErrorDelegate {
    private(set) var wasErrorReceived = false

    func didReceiveError(sender: ErrorReportable, error: NSError) {
        wasErrorReceived = true
    }
}
