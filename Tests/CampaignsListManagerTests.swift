import Quick
import Nimble
@testable import RInAppMessaging

class CampaignsListManagerTests: QuickSpec {

    override func spec() {

        describe("CampaignsListManager") {

            var manager: CampaignsListManager!
            var campaignsValidator: CampaignsValidatorMock!
            var campaignRepository: CampaignRepositoryMock!
            var readyCampaignDispatcher: ReadyCampaignDispatcherMock!
            var messageMixerService: MessageMixerServiceMock!
            var errorDelegate: ErrorDelegateMock!

            beforeEach {
                campaignsValidator = CampaignsValidatorMock()
                campaignRepository = CampaignRepositoryMock()
                readyCampaignDispatcher = ReadyCampaignDispatcherMock()
                messageMixerService = MessageMixerServiceMock()
                errorDelegate = ErrorDelegateMock()
                manager = CampaignsListManager(campaignsValidator: campaignsValidator,
                                               campaignRepository: campaignRepository,
                                               readyCampaignDispatcher: readyCampaignDispatcher,
                                               campaignTriggerAgent: CampaignTriggerAgentMock(),
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
                        expect(manager.scheduledTask).toNot(beNil())
                    }

                    it("will not report .requestError error") {
                        messageMixerService.mockedError = .requestError(.unknown)
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beFalse())
                    }
                }

                context("and ping call succeeded") {

                    let pingResponse = PingResponse(
                        nextPingMillis: 100,
                        currentPingMillis: 0,
                        data: TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 0).data)

                    beforeEach {
                        messageMixerService.mockedResponse = pingResponse
                    }

                    it("will request sync with received campaigns") {
                        manager.refreshList()
                        expect(campaignRepository.lastSyncCampaigns).to(elementsEqual(pingResponse.data))
                    }

                    it("will validate all existing campaigns") {
                        manager.refreshList()
                        expect(campaignsValidator.wasValidateCalled).to(beTrue())
                    }

                    it("will call dispatchIfNeeded") {
                        manager.refreshList()
                        expect(readyCampaignDispatcher.wasDispatchCalled).to(beTrue())
                    }

                    it("will schedule next ping call") {
                        manager.refreshList()
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
