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

private let impressionURL = URL(string: "https://impression.url")!

class ImpressionServiceSpec: QuickSpec {

    override func spec() {

        let requestQueue = DispatchQueue(label: "iam.test.request")
        let configData = ConfigData(rolloutPercentage: 100,
                                    endpoints: EndpointURL(
                                        ping: URL(string: "https://ping.url")!,
                                        displayPermission: nil,
                                        impression: impressionURL))
        let campaign = TestHelpers.generateCampaign(id: "test")
        let accountRepository = AccountRepository(userDataCache: UserDataCacheMock())
        let userInfoProvider = UserInfoProviderMock()
        accountRepository.setPreference(userInfoProvider)

        var service: ImpressionService!
        var configurationRepository: ConfigurationRepository!
        var httpSession: URLSessionMock!
        var errorDelegate: ErrorDelegateMock!
        let bundleInfo = BundleInfoMock.self

        func sendRequestAndWaitForResponse() {
            waitUntil { done in
                requestQueue.async {
                    service.pingImpression(impressions: [], campaignData: campaign.data)
                    done()
                }
            }
        }

        describe("ImpressionService") {

            beforeEach {
                URLSessionMock.startMockingURLSession()

                userInfoProvider.clear()
                configurationRepository = ConfigurationRepository()
                configurationRepository.saveConfiguration(configData)
                errorDelegate = ErrorDelegateMock()
                service = ImpressionService(accountRepository: accountRepository,
                                            configurationRepository: configurationRepository)
                service.errorDelegate = errorDelegate
                httpSession = URLSessionMock.mock(originalInstance: service.httpSession)
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()
            }

            it("will use provided URL in a request") {
                sendRequestAndWaitForResponse()
                expect(httpSession.sentRequest).toNot(beNil())
                expect(httpSession.sentRequest?.url).to(equal(configData.endpoints?.impression))
            }

            it("will report an error if url is not available") {
                configurationRepository.saveConfiguration(
                    ConfigData(rolloutPercentage: 100,
                               endpoints: EndpointURL(
                                ping: URL(string: "https://ping.url")!,
                                displayPermission: nil,
                                impression: nil)))

                sendRequestAndWaitForResponse()
                expect(errorDelegate.wasErrorReceived).to(beTrue())
            }

            context("when request succeeds") {

                beforeEach {
                    httpSession.httpResponse = HTTPURLResponse(url: configData.endpoints!.impression!,
                                                               statusCode: 200,
                                                               httpVersion: nil,
                                                               headerFields: nil)
                    httpSession.responseData = Data()
                }

                it("will not report any error") {
                    sendRequestAndWaitForResponse()
                    expect(errorDelegate.wasErrorReceived).to(beFalse())
                }
            }

            context("when request fails") {
                beforeEach {
                    Constants.Retry.Tests.setInitialDelayMS(1000)
                    Constants.Retry.Tests.setBackOffUpperBoundSeconds(1)
                }

                afterEach {
                    Constants.Retry.Tests.setDefaults()
                }

                it("will not report task failed error") {
                    httpSession.responseError = NSError(domain: "impression.error.test", code: 1, userInfo: nil)
                    sendRequestAndWaitForResponse()
                    expect(errorDelegate.wasErrorReceived).to(beFalse())
                }

                it("will retry for task failed error") {
                    httpSession.responseError = NSError(domain: "impression.error.test", code: 1, userInfo: nil)
                    sendRequestAndWaitForResponse()
                    expect(service.scheduledTask).toEventuallyNot(beNil())
                }

                context("and the status code equals to 5xx") {
                    for code in [500, 501, 520] {

                        it("will not report \(code) status code") {
                            httpSession.httpResponse = ImpressionURLResponse(statusCode: code)
                            sendRequestAndWaitForResponse()
                            expect(errorDelegate.wasErrorReceived).to(beFalse())
                        }

                        it("will retry for \(code) status code") {
                            httpSession.httpResponse = ImpressionURLResponse(statusCode: code)
                            sendRequestAndWaitForResponse()
                            expect(service.scheduledTask).toEventuallyNot(beNil())
                        }
                    }

                    it("will retry 3 times") {
                        var httpCalls = 0
                        httpSession.httpResponse = ImpressionURLResponse(statusCode: 500)
                        httpSession.onCompletedTask = {
                            httpCalls += 1
                        }
                        sendRequestAndWaitForResponse()
                        expect(service.scheduledTask).toEventuallyNot(beNil())
                        expect(httpCalls).toEventually(equal(4), timeout: .seconds(8))
                        expect(service.scheduledTask).toEventually(beNil())
                    }
                }

                context("and the status code equals to 4xx") {
                    for code in [401, 403, 422] {

                        it("will not report \(code) status code") {
                            httpSession.httpResponse = ImpressionURLResponse(statusCode: code)
                            sendRequestAndWaitForResponse()
                            expect(errorDelegate.wasErrorReceived).to(beFalse())
                        }

                        it("will not retry for \(code) status code") {
                            httpSession.httpResponse = ImpressionURLResponse(statusCode: code)
                            sendRequestAndWaitForResponse()
                            expect(service.scheduledTask).toAfterTimeout(beNil())
                        }
                    }
                }
            }

            context("when making a request") {
                beforeEach {
                    service.bundleInfo = bundleInfo
                    bundleInfo.reset()
                }

                it("will send a valid data object") {
                    sendRequestAndWaitForResponse()

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
                    userInfoProvider.userID = "userId"
                    userInfoProvider.idTrackingIdentifier = "tracking-id"

                    sendRequestAndWaitForResponse()

                    expect(httpSession.decodeSentData(modelType: ImpressionRequest.self))
                        .toEventuallyNot(beNil())
                    let request = httpSession.decodeSentData(modelType: ImpressionRequest.self)
                    expect(request?.userIdentifiers).to(elementsEqualOrderAgnostic([
                        UserIdentifier(type: .idTrackingIdentifier, identifier: "tracking-id"),
                        UserIdentifier(type: .userId, identifier: "userId")]))
                }

                it("will send required headers") {
                    userInfoProvider.accessToken = "token"

                    sendRequestAndWaitForResponse()

                    let Keys = Constants.Request.Header.self
                    expect(httpSession.sentRequest?.allHTTPHeaderFields).toEventuallyNot(beEmpty())
                    let headers = httpSession.sentRequest?.allHTTPHeaderFields
                    expect(headers?[Keys.subscriptionID]).to(equal(BundleInfoMock.inAppSubscriptionId))
                    expect(headers?[Keys.deviceID]).toNot(beEmpty())
                    expect(headers?[Keys.authorization]).to(equal("OAuth2 token"))
                }

                it("will send impressions excluding `impression` type to RAnalytics with all required properties") {
                    bundleInfo.inAppSubscriptionIdMock = "sub-id"
                    bundleInfo.analyticsAccountNumberMock = 111
                    let impressionTypes: [ImpressionType] = [.actionOne, .actionTwo, .exit, .clickContent, .invalid, .optOut, .impression]

                    expect {
                        service.pingImpression(impressions: impressionTypes.map { Impression(type: $0, timestamp: 1) },
                                               campaignData: campaign.data)
                    }.toEventually(postNotifications(containElementSatisfying({
                        let params = $0.object as? [String: Any]
                        let data = params?["eventData"] as? [String: Any]
                        let impressions = data?[Constants.RAnalytics.Keys.impressions] as? [[String: Any]]

                        return data != nil &&
                        impressions?.count == impressionTypes.count - 1 &&
                        impressions?.first(where: {
                            ($0[Constants.RAnalytics.Keys.action] as? Int) == ImpressionType.impression.rawValue
                        }) == nil &&
                        data?[Constants.RAnalytics.Keys.subscriptionID] as? String == bundleInfo.inAppSubscriptionIdMock &&
                        data?[Constants.RAnalytics.Keys.campaignID] as? String == campaign.id &&
                        params?["customAccNumber"] as? NSNumber == bundleInfo.analyticsAccountNumberMock
                    })))
                }
            }

            context("when building a request body") {
                beforeEach {
                    BundleInfoMock.reset()
                    service.bundleInfo = BundleInfoMock.self
                }

                func evaluateMetadataError(_ error: RequestError?) {
                    expect(error).toNot(beNil())

                    guard case .missingMetadata = error else {

                        fail("Unexpected error type \(String(describing: error)). Expected .missingMetadata)")
                        return
                    }
                }

                func evaluateParametersError(_ error: RequestError?) {
                    expect(error).toNot(beNil())

                    guard case .missingParameters = error else {

                        fail("Unexpected error type \(String(describing: error)). Expected .missingParameters)")
                        return
                    }
                }

                it("will return RequestError.missingMetadata error if host app version is missing") {
                    BundleInfoMock.appVersionMock = nil

                    let error = service.buildHttpBody(with: nil).getError() as? RequestError
                    evaluateMetadataError(error)
                }

                it("will return RequestError.missingMetadata error if sdk version is missing") {
                    BundleInfoMock.inAppSdkVersionMock = nil

                    let error = service.buildHttpBody(with: nil).getError() as? RequestError
                    evaluateMetadataError(error)
                }

                it("will return RequestError.missingParameters error if parameters is nil") {
                    let result = service.buildHttpBody(with: nil)
                    let error = result.getError() as? RequestError

                    evaluateParametersError(error)
                }

                it("will return RequestError.missingParameters error if parameters is empty") {
                    let result = service.buildHttpBody(with: [:])
                    let error = result.getError() as? RequestError

                    evaluateParametersError(error)
                }

                it("will return RequestError.missingParameters error if impressions parameters is missing") {
                    let result = service.buildHttpBody(with: ["campaign": campaign.data])
                    let error = result.getError() as? RequestError

                    evaluateParametersError(error)
                }

                it("will return RequestError.missingParameters error if campaign parameters is missing") {
                    let result = service.buildHttpBody(with: ["impressions": [Impression(type: .exit, timestamp: 2)]])
                    let error = result.getError() as? RequestError

                    evaluateParametersError(error)
                }
            }
        }
    }
}

private class ImpressionURLResponse: HTTPURLResponse {
    init?(statusCode: Int) {
        super.init(url: impressionURL,
                   statusCode: statusCode,
                   httpVersion: nil,
                   headerFields: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
