import Quick
import Nimble
@testable import RInAppMessaging

class CampaignTriggerAgentTests: QuickSpec {

    override func spec() {

        describe("CampaignTriggerAgentTests") {

            let testCampaign = TestHelpers.generateCampaign(id: "test")

            var eventMatcher: EventMatcherMock!
            var campaignDispatcher: CampaignDispatcherMock!
            var campaignTriggerAgent: CampaignTriggerAgent!

            beforeEach {
                eventMatcher = EventMatcherMock()
                campaignDispatcher = CampaignDispatcherMock()
                campaignTriggerAgent = CampaignTriggerAgent(eventMatcher: eventMatcher,
                                                            readyCampaignDispatcher: campaignDispatcher)
            }

            it("will add campaign to the queue when events match") {
                eventMatcher.simulateMatchingSuccess = true
                campaignTriggerAgent.trigger(campaign: testCampaign,
                                             triggeredEvents: [])
                expect(campaignDispatcher.addedCampaigns).to(elementsEqual([testCampaign]))
            }

            it("will not dispatch campaign when events don't match") {
                eventMatcher.simulateMatchingSuccess = false
                campaignTriggerAgent.trigger(campaign: testCampaign,
                                             triggeredEvents: [])
                expect(campaignDispatcher.addedCampaigns).to(beEmpty())
            }

            it("will not dispatch campaign when events coulnd't be triggered") {
                eventMatcher.simulateMatchingSuccess = true
                eventMatcher.simulateMatcherError = .providedSetOfEventsHaveAlreadyBeenUsed
                campaignTriggerAgent.trigger(campaign: testCampaign,
                                             triggeredEvents: [])
                expect(campaignDispatcher.addedCampaigns).to(beEmpty())
            }
        }
    }
}
