import Quick
import Nimble
import class Foundation.NSError
@testable import RInAppMessaging

class CampaignsListManagerSpec: QuickSpec {

    override func spec() {

        describe("CampaignsListManager") {

            var manager: CampaignsListManager!
            var campaignRepository: CampaignRepositoryMock!
            var messageMixerService: MessageMixerServiceMock!
            var campaignTriggerAgent: CampaignTriggerAgentMock!
            var errorDelegate: ErrorDelegateMock!

            beforeEach {
                campaignRepository = CampaignRepositoryMock()
                messageMixerService = MessageMixerServiceMock()
                errorDelegate = ErrorDelegateMock()
                campaignTriggerAgent = CampaignTriggerAgentMock()
                manager = CampaignsListManager(campaignRepository: campaignRepository,
                                               campaignTriggerAgent: campaignTriggerAgent,
                                               messageMixerService: messageMixerService)
                manager.errorDelegate = errorDelegate
            }

            context("when refrreshList is called") {
                it("will make ping call") {
                    manager.refreshList()
                    expect(messageMixerService.wasPingCalled).to(beTrue())
                }

                context("and service error has occured") {

                    beforeEach {
                        Constants.Retry.Tests.setInitialDelayMS(100)
                        Constants.Retry.Tests.setBackOffUpperBoundSeconds(1)
                    }

                    afterEach {
                        Constants.Retry.Tests.setDefaults()
                    }

                    it("will not retry for .invalidConfiguration error") {
                        messageMixerService.mockedError = .invalidConfiguration
                        manager.refreshList()
                        expect(manager.scheduledTask).to(beNil())
                    }

                    it("will not retry for .jsonDecodingError error") {
                        messageMixerService.mockedError = .jsonDecodingError(NSError.emptyError)
                        manager.refreshList()
                        expect(manager.scheduledTask).to(beNil())
                    }

                    it("will report .invalidConfiguration error") {
                        messageMixerService.mockedError = .invalidConfiguration
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    it("will report .jsonDecodingError error") {
                        messageMixerService.mockedError = .jsonDecodingError(NSError.emptyError)
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    it("will retry for .requestError error") {
                        messageMixerService.mockedError = .requestError(.unknown)
                        manager.refreshList()
                        expect(manager.scheduledTask).toEventuallyNot(beNil())
                    }

                    it("will report .requestError error") {
                        messageMixerService.mockedError = .requestError(.unknown)
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    it("will retry for .tooManyRequestsError error") {
                        messageMixerService.mockedError = .tooManyRequestsError
                        manager.refreshList()
                        expect(manager.scheduledTask).toEventuallyNot(beNil())
                    }

                    it("will not report .tooManyRequestsError error") {
                        messageMixerService.mockedError = .tooManyRequestsError
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beFalse())
                    }

                    it("will not retry for .invalidRequestError error") {
                        messageMixerService.mockedError = .invalidRequestError(404)
                        manager.refreshList()
                        expect(manager.scheduledTask).toAfterTimeout(beNil())
                    }

                    it("will report .invalidRequestError error") {
                        messageMixerService.mockedError = .invalidRequestError(404)
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    it("will retry for .internalServerError error") {
                        messageMixerService.mockedError = .internalServerError(500)
                        manager.refreshList()
                        expect(manager.scheduledTask).toEventuallyNot(beNil())
                    }

                    it("should retry 3 times for .internalServerError error") {
                        messageMixerService.mockedError = .internalServerError(500)
                        manager.refreshList()
                        expect(manager.scheduledTask).toEventuallyNot(beNil())
                        expect(messageMixerService.pingCallCount).toEventually(equal(4), timeout: .seconds(12))
                        expect(manager.scheduledTask).toEventually(beNil())
                    }

                    it("will report .internalServerError error") {
                        messageMixerService.mockedError = .internalServerError(500)
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    context("and refreshList was called again") {

                        it("shouldn't call ping if the call is already scheduled (should call only once)") {
                            Constants.Retry.Tests.setInitialDelayMS(2000)
                            messageMixerService.mockedError = .requestError(.unknown)
                            manager.refreshList()
                            expect(manager.scheduledTask).toEventuallyNot(beNil())

                            messageMixerService.mockedResponse = PingResponse(nextPingMilliseconds: .max, currentPingMilliseconds: 0, data: [])
                            messageMixerService.wasPingCalled = false
                            manager.refreshList()
                            expect(messageMixerService.wasPingCalled).toAfterTimeout(beFalse()) // checks if the call above was ignored
                            expect(messageMixerService.wasPingCalled).toEventually(beTrue(), timeout: .seconds(2)) // scheduled retry call (after 2s)
                        }
                    }
                }

                context("and ping call succeeded") {

                    let pingResponse = PingResponse(
                        nextPingMilliseconds: 100,
                        currentPingMilliseconds: 0,
                        data: TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 0).data)

                    beforeEach {
                        messageMixerService.mockedResponse = pingResponse
                    }

                    it("will request sync with received campaigns") {
                        manager.refreshList()
                        expect(campaignRepository.lastSyncCampaigns).to(elementsEqual(pingResponse.data))
                    }

                    it("will call validateAndTriggerCampaigns") {
                        manager.refreshList()
                        expect(campaignTriggerAgent.wasValidateAndTriggerCampaignsCalled).to(beTrue())
                    }

                    it("will schedule next ping call") {
                        manager.refreshList()
                        expect(messageMixerService.wasPingCalled).toEventually(beTrue()) // wait
                        messageMixerService.wasPingCalled = false
                        expect(messageMixerService.wasPingCalled).toEventually(beTrue())
                    }
                }
            }
        }
    }
}
