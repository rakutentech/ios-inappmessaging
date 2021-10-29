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

class ImpressionServiceSpec: QuickSpec {

    override func spec() {

        let requestQueue = DispatchQueue(label: "iam.test.request")
        let configData = ConfigData(rolloutPercentage: 100,
                                    endpoints: EndpointURL(
                                        ping: URL(string: "https://ping.url")!,
                                        displayPermission: nil,
                                        impression: URL(string: "https://impression.url")!))
        let campaign = TestHelpers.generateCampaign(id: "test")
        let accountRepository = AccountRepository(userDataCache: UserDataCacheMock())
        let userInfoProvider = UserInfoProviderMock()
        accountRepository.setPreference(userInfoProvider)

        var service: ImpressionService!
        var configurationRepository: ConfigurationRepository!
        var httpSession: URLSessionMock!
        var errorDelegate: ErrorDelegateMock!

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
                expect(errorDelegate.wasErrorReceived).toEventually(beTrue())
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
                    expect(errorDelegate.wasErrorReceived).toAfterTimeout(beFalse())
                }
            }

            context("when request fails") {
                beforeEach {
                    httpSession.responseError = NSError(domain: "config.error.test", code: 1, userInfo: nil)
                }

                it("will report an error") {
                    sendRequestAndWaitForResponse()
                    expect(errorDelegate.wasErrorReceived).toEventually(beTrue())
                }
            }

            context("when making a request") {
                beforeEach {
                    service.bundleInfo = BundleInfoMock.self
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

private class ErrorDelegateMock: ErrorDelegate {
    private(set) var wasErrorReceived = false

    func didReceiveError(sender: ErrorReportable, error: NSError) {
        wasErrorReceived = true
    }
}
