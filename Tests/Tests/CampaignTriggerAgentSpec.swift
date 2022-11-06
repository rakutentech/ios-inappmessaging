import Quick
import Nimble
@testable import RInAppMessaging

class CampaignTriggerAgentSpec: QuickSpec {

    override func spec() {

        describe("CampaignTriggerAgent") {

            let testCampaign = TestHelpers.generateCampaign(id: "test")
            let testTooltip = TestHelpers.generateTooltip(id: "test")

            var eventMatcher: EventMatcherMock!
            var campaignDispatcher: CampaignDispatcherMock!
            var campaignTriggerAgent: CampaignTriggerAgent!
            var campaignsValidator: CampaignsValidatorMock!
            var tooltipDispatcher: TooltipDispatcherMock!

            beforeEach {
                eventMatcher = EventMatcherMock()
                campaignDispatcher = CampaignDispatcherMock()
                campaignsValidator = CampaignsValidatorMock()
                tooltipDispatcher = TooltipDispatcherMock()
                campaignTriggerAgent = CampaignTriggerAgent(eventMatcher: eventMatcher,
                                                            readyCampaignDispatcher: campaignDispatcher,
                                                            tooltipDispatcher: tooltipDispatcher,
                                                            campaignsValidator: campaignsValidator)
            }

            context("when triggering campaigns") {

                context("when events match") {
                    beforeEach {
                        eventMatcher.simulateMatchingSuccess = true
                    }
                    it("will add a campaign to the queue when events match") {
                        campaignsValidator.campaignsToTrigger = [testCampaign]
                        campaignTriggerAgent.validateAndTriggerCampaigns()

                        expect(campaignDispatcher.addedCampaignIDs).to(elementsEqual([testCampaign.id]))
                    }

                    it("will not add campaigns to Tooltip Dispatcher") {
                        campaignsValidator.campaignsToTrigger = [testCampaign]
                        campaignTriggerAgent.validateAndTriggerCampaigns()

                        expect(tooltipDispatcher.needsDisplayTooltips).to(beEmpty())
                    }

                    it("will not dispatch a campaign when events coulnd't be triggered") {
                        eventMatcher.simulateMatcherError = .providedSetOfEventsHaveAlreadyBeenUsed
                        campaignsValidator.campaignsToTrigger = [testCampaign]
                        campaignTriggerAgent.validateAndTriggerCampaigns()

                        expect(campaignDispatcher.addedCampaignIDs).to(beEmpty())
                    }
                }

                it("will validate campaigns") {
                    campaignsValidator.campaignsToTrigger = [testCampaign]
                    campaignTriggerAgent.validateAndTriggerCampaigns()
                    expect(campaignsValidator.wasValidateCalled).to(beTrue())
                }

                it("will not dispatch a campaign when events don't match") {
                    eventMatcher.simulateMatchingSuccess = false
                    campaignsValidator.campaignsToTrigger = [testCampaign]
                    campaignTriggerAgent.validateAndTriggerCampaigns()

                    expect(campaignDispatcher.addedCampaignIDs).to(beEmpty())
                }
            }

            context("when triggering tooltip") {

                context("when events match") {
                    beforeEach {
                        eventMatcher.simulateMatchingSuccess = true
                    }
                    it("will mark tooltip as ready to display if needed") {
                        campaignsValidator.campaignsToTrigger = [testTooltip]
                        campaignTriggerAgent.validateAndTriggerCampaigns()

                        expect(tooltipDispatcher.needsDisplayTooltips).to(elementsEqual([testTooltip]))
                    }

                    it("will not add tooltips to campaigns queue") {
                        campaignsValidator.campaignsToTrigger = [testTooltip]
                        campaignTriggerAgent.validateAndTriggerCampaigns()

                        expect(campaignDispatcher.addedCampaignIDs).to(beEmpty())
                    }

                    it("will not dispatch a tooltip when events coulnd't be triggered") {
                        eventMatcher.simulateMatcherError = .providedSetOfEventsHaveAlreadyBeenUsed
                        campaignsValidator.campaignsToTrigger = [testTooltip]
                        campaignTriggerAgent.validateAndTriggerCampaigns()

                        expect(tooltipDispatcher.needsDisplayTooltips).to(beEmpty())
                    }
                }

                it("will validate tooltips") {
                    campaignsValidator.campaignsToTrigger = [testTooltip]
                    campaignTriggerAgent.validateAndTriggerCampaigns()
                    expect(campaignsValidator.wasValidateCalled).to(beTrue())
                }

                it("will not dispatch a tooltip when events don't match") {
                    eventMatcher.simulateMatchingSuccess = false
                    campaignsValidator.campaignsToTrigger = [testTooltip]
                    campaignTriggerAgent.validateAndTriggerCampaigns()

                    expect(tooltipDispatcher.needsDisplayTooltips).to(beEmpty())
                }
            }
        }
    }
}
