import Quick
import Nimble
import class Foundation.NSError
@testable import RInAppMessaging

class CampaignsListManagerSpec: QuickSpec {

    override func spec() {

        describe("CampaignsListManager") {

            var manager: CampaignsListManager!
            var campaignRepository: CampaignRepositoryMock!
            var pingService: PingServiceMock!
            var campaignTriggerAgent: CampaignTriggerAgentMock!
            var errorDelegate: ErrorDelegateMock!
            var configurationRepository: ConfigurationRepository!

            beforeEach {
                campaignRepository = CampaignRepositoryMock()
                pingService = PingServiceMock()
                errorDelegate = ErrorDelegateMock()
                campaignTriggerAgent = CampaignTriggerAgentMock()
                configurationRepository = ConfigurationRepository()
                configurationRepository.saveIAMModuleConfiguration(
                    InAppMessagingModuleConfiguration(configURLString: nil, subscriptionID: nil, isTooltipFeatureEnabled: true))
                manager = CampaignsListManager(campaignRepository: campaignRepository,
                                               campaignTriggerAgent: campaignTriggerAgent,
                                               pingService: pingService,
                                               configurationRepository: configurationRepository)
                manager.errorDelegate = errorDelegate
            }

            context("when refrreshList is called") {
                it("will make ping call") {
                    manager.refreshList()
                    expect(pingService.wasPingCalled).to(beTrue())
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
                        pingService.mockedError = .invalidConfiguration
                        manager.refreshList()
                        expect(manager.scheduledTask).to(beNil())
                    }

                    it("will not retry for .jsonDecodingError error") {
                        pingService.mockedError = .jsonDecodingError(NSError.emptyError)
                        manager.refreshList()
                        expect(manager.scheduledTask).to(beNil())
                    }

                    it("will report .invalidConfiguration error") {
                        pingService.mockedError = .invalidConfiguration
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    it("will report .jsonDecodingError error") {
                        pingService.mockedError = .jsonDecodingError(NSError.emptyError)
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    it("will retry for .requestError error") {
                        pingService.mockedError = .requestError(.unknown)
                        manager.refreshList()
                        expect(manager.scheduledTask).toEventuallyNot(beNil())
                    }

                    it("will report .requestError error") {
                        pingService.mockedError = .requestError(.unknown)
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    it("will retry for .tooManyRequestsError error") {
                        pingService.mockedError = .tooManyRequestsError
                        manager.refreshList()
                        expect(manager.scheduledTask).toEventuallyNot(beNil())
                    }

                    it("will not report .tooManyRequestsError error") {
                        pingService.mockedError = .tooManyRequestsError
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beFalse())
                    }

                    it("will not retry for .invalidRequestError error") {
                        pingService.mockedError = .invalidRequestError(404)
                        manager.refreshList()
                        expect(manager.scheduledTask).toAfterTimeout(beNil())
                    }

                    it("will report .invalidRequestError error") {
                        pingService.mockedError = .invalidRequestError(404)
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    it("will retry for .internalServerError error") {
                        pingService.mockedError = .internalServerError(500)
                        manager.refreshList()
                        expect(manager.scheduledTask).toEventuallyNot(beNil())
                    }

                    it("should retry 3 times for .internalServerError error") {
                        pingService.mockedError = .internalServerError(500)
                        manager.refreshList()
                        expect(manager.scheduledTask).toEventuallyNot(beNil())
                        expect(pingService.pingCallCount).toEventually(equal(4), timeout: .seconds(12))
                        expect(manager.scheduledTask).toEventually(beNil())
                    }

                    it("will report .internalServerError error") {
                        pingService.mockedError = .internalServerError(500)
                        manager.refreshList()
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    context("and refreshList was called again") {

                        it("shouldn't call ping if the call is already scheduled (should call only once)") {
                            Constants.Retry.Tests.setInitialDelayMS(2000)
                            pingService.mockedError = .requestError(.unknown)
                            manager.refreshList()
                            expect(manager.scheduledTask).toEventuallyNot(beNil())

                            pingService.mockedResponse = PingResponse(nextPingMilliseconds: .max, currentPingMilliseconds: 0, data: [])
                            pingService.wasPingCalled = false
                            manager.refreshList()
                            expect(pingService.wasPingCalled).toAfterTimeout(beFalse()) // checks if the call above was ignored
                            expect(pingService.wasPingCalled).toEventually(beTrue(), timeout: .seconds(2)) // scheduled retry call (after 2s)
                        }
                    }
                }

                context("and ping call succeeded") {

                    let pingResponse = PingResponse(
                        nextPingMilliseconds: 100,
                        currentPingMilliseconds: 0,
                        data: TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 0).data)

                    beforeEach {
                        pingService.mockedResponse = pingResponse
                    }

                    context("and tooltip feature is disabled") {
                        beforeEach {
                            configurationRepository.saveIAMModuleConfiguration(
                                InAppMessagingModuleConfiguration(configURLString: nil, subscriptionID: nil, isTooltipFeatureEnabled: false))
                        }
                        it("will request sync with ignoring tooltips") {
                            manager.refreshList()
                            expect(campaignRepository.didSyncIgnoringTooltips).to(beTrue())
                        }
                    }

                    context("and tooltip feature is enabled") {
                        beforeEach {
                            configurationRepository.saveIAMModuleConfiguration(
                                InAppMessagingModuleConfiguration(configURLString: nil, subscriptionID: nil, isTooltipFeatureEnabled: true))
                        }
                        it("will request sync without ignoring tooltips") {
                            manager.refreshList()
                            expect(campaignRepository.didSyncIgnoringTooltips).to(beFalse())
                        }
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
                        expect(pingService.wasPingCalled).toEventually(beTrue()) // wait
                        pingService.wasPingCalled = false
                        expect(pingService.wasPingCalled).toEventually(beTrue())
                    }
                }
            }
        }
    }
}
