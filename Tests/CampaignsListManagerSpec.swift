import Quick
import Nimble
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

                    it("will not report .requestError error") {
                        messageMixerService.mockedError = .requestError(.unknown)
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beFalse())
                    }

                    it("will retry for .tooManyRequestsError error") {
                        messageMixerService.mockedError = .tooManyRequestsError
                        manager.refreshList()
                        expect(manager.scheduledTask).toEventuallyNot(beNil())
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

private class ErrorDelegateMock: ErrorDelegate {
    private(set) var wasErrorReceived = false

    func didReceiveError(sender: ErrorReportable, error: NSError) {
        wasErrorReceived = true
    }
}
