import Quick
import Nimble
@testable import RInAppMessaging

class CampaignTriggerAgentSpec: QuickSpec {

    override func spec() {

        describe("CampaignTriggerAgent") {

            let testCampaign = TestHelpers.generateCampaign(id: "test")

            var eventMatcher: EventMatcherMock!
            var campaignDispatcher: CampaignDispatcherMock!
            var campaignTriggerAgent: CampaignTriggerAgent!
            var campaignsValidator: CampaignsValidatorMock!

            beforeEach {
                eventMatcher = EventMatcherMock()
                campaignDispatcher = CampaignDispatcherMock()
                campaignsValidator = CampaignsValidatorMock()
                campaignTriggerAgent = CampaignTriggerAgent(eventMatcher: eventMatcher,
                                                            readyCampaignDispatcher: campaignDispatcher,
                                                            campaignsValidator: campaignsValidator)
            }

            context("when events match") {
                beforeEach {
                    eventMatcher.simulateMatchingSuccess = true
                }
                it("will add campaign to the queue when events match") {
                    campaignsValidator.campaignsToTrigger = [testCampaign]
                    campaignTriggerAgent.validateAndTriggerCampaigns()

                    expect(campaignDispatcher.addedCampaigns).to(elementsEqual([testCampaign]))
                }

                it("will not dispatch campaign when events coulnd't be triggered") {
                    eventMatcher.simulateMatcherError = .providedSetOfEventsHaveAlreadyBeenUsed
                    campaignsValidator.campaignsToTrigger = [testCampaign]
                    campaignTriggerAgent.validateAndTriggerCampaigns()

                    expect(campaignDispatcher.addedCampaigns).to(beEmpty())
                }
            }

            it("will validate campaigns") {
                campaignsValidator.campaignsToTrigger = [testCampaign]
                campaignTriggerAgent.validateAndTriggerCampaigns()
                expect(campaignsValidator.wasValidateCalled).to(beTrue())
            }

            it("will not dispatch campaign when events don't match") {
                eventMatcher.simulateMatchingSuccess = false
                campaignsValidator.campaignsToTrigger = [testCampaign]
                campaignTriggerAgent.validateAndTriggerCampaigns()

                expect(campaignDispatcher.addedCampaigns).to(beEmpty())
            }
        }
    }
}
