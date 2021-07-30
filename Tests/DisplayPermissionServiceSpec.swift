import Quick
import Nimble
@testable import RInAppMessaging

class DisplayPermissionServiceSpec: QuickSpec {

    override func spec() {

        let requestQueue = DispatchQueue(label: "iam.test.request")
        let configData = ConfigData(rolloutPercentage: 100,
                                    endpoints: EndpointURL(
                                        ping: URL(string: "https://ping.url")!,
                                        displayPermission: URL(string: "https://permission.url")!,
                                        impression: nil))
        let campaign = TestHelpers.generateCampaign(id: "test")

        var service: DisplayPermissionService!
        var preferenceRepository: AccountRepositoryType!
        var configurationRepository: ConfigurationRepository!
        var campaignRepository: CampaignRepositoryMock!
        var httpSession: URLSessionMock!

        func sendRequestAndWaitForResponse() {
            waitUntil { done in
                requestQueue.async {
                    _ = service.checkPermission(forCampaign: campaign.data)
                    done()
                }
            }
        }

        describe("DisplayPermissionService") {

            beforeEach {
                URLSessionMock.startMockingURLSession()

                preferenceRepository = AccountRepository()
                campaignRepository = CampaignRepositoryMock()
                configurationRepository = ConfigurationRepository()
                configurationRepository.saveConfiguration(configData)
                service = DisplayPermissionService(campaignRepository: campaignRepository,
                                                   preferenceRepository: preferenceRepository,
                                                   configurationRepository: configurationRepository)
                httpSession = URLSessionMock.mock(originalInstance: service.httpSession)
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()
            }

            it("will use provided URL in a request") {
                sendRequestAndWaitForResponse()
                expect(httpSession.sentRequest).toNot(beNil())
                expect(httpSession.sentRequest?.url).to(equal(configData.endpoints?.displayPermission))
            }

            it("will deny permission if url is not available") {
                configurationRepository.saveConfiguration(
                    ConfigData(rolloutPercentage: 100,
                               endpoints: EndpointURL(
                                ping: URL(string: "https://ping.url")!,
                                displayPermission: nil,
                                impression: nil)))
                waitUntil { done in
                    requestQueue.async {
                        let result = service.checkPermission(forCampaign: campaign.data)
                        expect(result.display).to(beFalse())
                        expect(result.performPing).to(beFalse())
                        done()
                    }
                }
                expect(httpSession.sentRequest).to(beNil())
            }

            context("when request succeeds") {

                beforeEach {
                    httpSession.httpResponse = HTTPURLResponse(url: configData.endpoints!.displayPermission!,
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
                                expect(response.display).to(beFalse())
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
                            expect(response.display).to(beFalse())
                            expect(response.performPing).to(beFalse())
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
                    campaignRepository.lastSyncInMilliseconds = 111
                    sendRequestAndWaitForResponse()

                    let request = httpSession.decodeSentData(modelType: DisplayPermissionRequest.self)

                    expect(request).toNot(beNil())
                    expect(request?.subscriptionId).to(equal(BundleInfoMock.inAppSubscriptionId))
                    expect(request?.campaignId).to(equal(campaign.id))
                    expect(request?.platform).to(equal(.ios))
                    expect(request?.appVersion).to(equal(BundleInfoMock.appVersion))
                    expect(request?.sdkVersion).to(equal(BundleInfoMock.inAppSdkVersion))
                    expect(request?.locale).to(equal(Locale.current.normalizedIdentifier))
                    expect(request?.lastPingInMilliseconds).to(equal(111))
                }

                it("will send user preferences in the request") {
                    preferenceRepository.setPreference(UserInfoProviderMock(userID: "userId", rakutenId: "rakutenId"))

                    sendRequestAndWaitForResponse()

                    let request = httpSession.decodeSentData(modelType: DisplayPermissionRequest.self)

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
                    expect(headers?[Keys.authorization]).to(equal("OAuth2 token"))
                }

                context("and required data is missing") {

                    func evaluateMetadataError(_ error: RequestError?) {
                        expect(error).toNot(beNil())

                        guard case .bodyEncodingError(let enclosedError) = error,
                            case .missingMetadata = enclosedError as? RequestError else {

                            fail("Unexpected error type \(String(describing: error)). Expected .bodyEncodingError(.missingMetadata)")
                            return
                        }
                    }

                    it("will return RequestError.missingMetadata error if subscription id is missing") {
                        BundleInfoMock.inAppSubscriptionIdMock = nil

                        sendRequestAndWaitForResponse()

                        let error = service.lastResponse?.getError()
                        evaluateMetadataError(error)
                    }

                    it("will return RequestError.missingMetadata error if host app version is missing") {
                        BundleInfoMock.appVersionMock = nil

                        sendRequestAndWaitForResponse()

                        let error = service.lastResponse?.getError()
                        evaluateMetadataError(error)
                    }

                    it("will return RequestError.missingMetadata error if sdk version is missing") {
                        BundleInfoMock.inAppSdkVersionMock = nil

                        sendRequestAndWaitForResponse()

                        let error = service.lastResponse?.getError()
                        evaluateMetadataError(error)
                    }
                    context("when building request body") {

                        func evaluateParametersError(_ error: RequestError?) {
                            expect(error).toNot(beNil())

                            guard case .missingParameters = error else {

                                fail("Unexpected error type \(String(describing: error)). Expected .missingParameters)")
                                return
                            }
                        }

                        it("will return RequestError.missingParameters error if parameters is nil") {
                            let result = service.buildHttpBody(with: nil)
                            let error = result.getError() as? RequestError

                            evaluateParametersError(error)
                        }

                        it("will return RequestError.missingParameters error if required parameters are missing") {
                            let result = service.buildHttpBody(with: ["notCampaignId": "definitelyNotAValue"])
                            let error = result.getError() as? RequestError

                            evaluateParametersError(error)
                        }
                    }
                }
            }
        }
    }
}
