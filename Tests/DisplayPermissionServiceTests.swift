import Quick
import Nimble
@testable import RInAppMessaging

class DisplayPermissionServiceTests: QuickSpec {

    override func spec() {

        let requestQueue = DispatchQueue(label: "iam.test.request")
        let configData = ConfigData(enabled: true,
                                    endpoints: EndpointURL(
                                        ping: URL(string: "https://ping.url")!,
                                        displayPermission: URL(string: "https://permission.url")!,
                                        impression: nil))
        let campaign = TestHelpers.generateCampaign(id: "test")

        var service: DisplayPermissionService!
        var preferenceRepository: IAMPreferenceRepository!
        var configurationRepository: ConfigurationRepository!
        var campaignRepository: CampaignRepositoryMock!
        var httpSession: URLSessionMock!

        describe("DisplayPremissionService") {

            beforeEach {
                URLSessionMock.startMockingURLSession()

                preferenceRepository = IAMPreferenceRepository()
                campaignRepository = CampaignRepositoryMock()
                configurationRepository = ConfigurationRepository()
                configurationRepository.saveConfiguration(configData)
                service = DisplayPermissionService(campaignRepository: campaignRepository,
                                                   preferenceRepository: preferenceRepository,
                                                   configurationRepository: configurationRepository)
                httpSession = URLSessionMock(originalInstance: service.httpSession)
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()
            }

            it("will use provided URL in a request") {
                waitUntil { done in
                    requestQueue.async {
                        _ = service.checkPermission(forCampaign: campaign.data)
                        done()
                    }
                }
                expect(httpSession.sentRequest).toNot(beNil())
                expect(httpSession.sentRequest?.url).to(equal(configData.endpoints.displayPermission))
            }

            it("will give permission if url is not available") {
                configurationRepository.saveConfiguration(
                    ConfigData(enabled: true,
                               endpoints: EndpointURL(
                                ping: URL(string: "https://ping.url")!,
                                displayPermission: nil,
                                impression: nil)))
                waitUntil { done in
                    requestQueue.async {
                        let result = service.checkPermission(forCampaign: campaign.data)
                        expect(result.display).to(beTrue())
                        expect(result.performPing).to(beFalse())
                        done()
                    }
                }
                expect(httpSession.sentRequest).to(beNil())
            }

            context("when request succeeds") {

                beforeEach {
                    httpSession.httpResponse = HTTPURLResponse(url: configData.endpoints.displayPermission!,
                                                               statusCode: 200,
                                                               httpVersion: nil,
                                                               headerFields: nil)
                }

                context("and payload is valid") {

                    it("will return a valid data model") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "displayPermission_success")

                        waitUntil { done in
                            requestQueue.async {
                                let response = service.checkPermission(forCampaign: campaign.data)
                                expect(response.display).to(beFalse())
                                expect(response.performPing).to(beTrue())
                                done()
                            }
                        }
                    }
                }

                context("and payload is not valid") {

                    it("will return a default data model") {
                        httpSession.responseData = TestHelpers.getJSONData(fileName: "displayPermission_invalid")

                        waitUntil { done in
                            requestQueue.async {
                                let response = service.checkPermission(forCampaign: campaign.data)
                                expect(response.display).to(beTrue())
                                expect(response.performPing).to(beFalse())
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

                it("will return a default data model") {
                    waitUntil { done in
                        requestQueue.async {
                            let response = service.checkPermission(forCampaign: campaign.data)
                            expect(response.display).to(beTrue())
                            expect(response.performPing).to(beFalse())
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
                    campaignRepository.lastSyncInMilliseconds = 111
                    waitUntil { done in
                        requestQueue.async {
                            _ = service.checkPermission(forCampaign: campaign.data)
                            done()
                        }
                    }

                    let request = httpSession.decodeSentData(modelType: DisplayPermissionRequest.self)

                    expect(request).toNot(beNil())
                    expect(request?.subscriptionId).to(equal(BundleInfoMock.inAppSubscriptionId))
                    expect(request?.campaignId).to(equal(campaign.id))
                    expect(request?.platform).to(equal(.ios))
                    expect(request?.appVersion).to(equal(BundleInfoMock.appVersion))
                    expect(request?.sdkVersion).to(equal(BundleInfoMock.inAppSdkVersion))
                    expect(request?.locale).to(equal(Locale.current.identifier))
                    expect(request?.lastPingInMilliseconds).to(equal(111))
                }

                it("will send user preferences in the request") {
                    preferenceRepository.setPreference(IAMPreferenceBuilder()
                        .setRakutenId("rakutenId")
                        .setUserId("userId")
                        .build())

                    waitUntil { done in
                        requestQueue.async {
                            _ = service.checkPermission(forCampaign: campaign.data)
                            done()
                        }
                    }

                    let request = httpSession.decodeSentData(modelType: DisplayPermissionRequest.self)

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
                            _ = service.checkPermission(forCampaign: campaign.data)
                            done()
                        }
                    }

                    let Keys = Constants.Request.Header.self
                    let headers = httpSession.sentRequest?.allHTTPHeaderFields
                    expect(headers).toNot(beEmpty())
                    expect(headers?[Keys.subscriptionID]).to(equal(BundleInfoMock.inAppSubscriptionId))
                    expect(headers?[Keys.authorization]).to(equal("OAuth2 rae-token"))
                }
            }
        }
    }
}
