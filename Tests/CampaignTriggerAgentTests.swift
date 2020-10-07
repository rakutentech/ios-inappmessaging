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

            context("when events match") {
                beforeEach {
                    eventMatcher.simulateMatchingSuccess = true
                }
                it("will add campaign to the queue when events match") {
                    campaignTriggerAgent.trigger(campaign: testCampaign,
                                                 triggeredEvents: [])
                    let addedCampaigns = campaignDispatcher.addedCampaignsWithContexts.map { $0.campaign }
                    expect(addedCampaigns).to(elementsEqual([testCampaign]))
                }

                it("will add contexts from the triggered events") {
                    let context1 = EventContext(id: "ctx1")
                    let context2 = EventContext(id: "ctx2", userInfo: ["info": "info"])
                    let event1 = Event(type: .custom, name: "e1")
                    event1.context = context1
                    let event2 = Event(type: .custom, name: "e2")
                    event2.context = context2

                    campaignTriggerAgent.trigger(campaign: testCampaign,
                                                 triggeredEvents: [event1, event2])
                    let addedContexts = campaignDispatcher.addedCampaignsWithContexts.first?.contexts ?? []
                    expect(addedContexts).to(contain([context1, context2]))
                }

                it("will not dispatch campaign when events coulnd't be triggered") {
                    eventMatcher.simulateMatcherError = .providedSetOfEventsHaveAlreadyBeenUsed
                    campaignTriggerAgent.trigger(campaign: testCampaign,
                                                 triggeredEvents: [])
                    expect(campaignDispatcher.addedCampaignsWithContexts).to(beEmpty())
                }
            }

            it("will not dispatch campaign when events don't match") {
                eventMatcher.simulateMatchingSuccess = false
                campaignTriggerAgent.trigger(campaign: testCampaign,
                                             triggeredEvents: [])
                expect(campaignDispatcher.addedCampaignsWithContexts).to(beEmpty())
            }
        }
    }
}
