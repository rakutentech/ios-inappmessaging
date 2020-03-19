import Quick
import Nimble
@testable import RInAppMessaging

class EventMatcherTests: QuickSpec {

    override func spec() {

        describe("EventMatcher") {

            let testCampaign = TestHelpers.generateCampaign(id: "test",
                                                            test: false, delay: 0,
                                                            maxImpressions: 1,
                                                            triggers: [
                                                                Trigger(type: .event,
                                                                        eventType: .appStart,
                                                                        eventName: "appStartTest",
                                                                        attributes: []),
                                                                Trigger(type: .event,
                                                                        eventType: .loginSuccessful,
                                                                        eventName: "loginSuccessfulTest",
                                                                        attributes: [])
                ]
            )

            var campaignRepository: CampaignRepositoryMock!
            var eventMatcher: EventMatcher!

            beforeEach {
                campaignRepository = CampaignRepositoryMock()
                eventMatcher = EventMatcher(campaignRepository: campaignRepository)
            }

            context("when removing events") {

                it("will throw error if events for given campaign weren't found") {
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent()], for: testCampaign)
                    }.to(throwError(EventMatcherError.couldntFindRequestedSetOfEvents))
                }

                it("will throw error if all events weren't found") {
                    campaignRepository.list = [testCampaign]
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                                  for: testCampaign)
                    }.to(throwError(EventMatcherError.couldntFindRequestedSetOfEvents))
                }

                it("will not persist normal events") {
                    campaignRepository.list = [testCampaign]
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    try? eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                               for: testCampaign)
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                                  for: testCampaign)
                    }.to(throwError(EventMatcherError.couldntFindRequestedSetOfEvents))
                }

                it("will succeed if all events were found") {
                    campaignRepository.list = [testCampaign]
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                                  for: testCampaign)
                    }.toNot(throwError())
                }

                it("will succeed again without need for persistent event to be logged") {
                    campaignRepository.list = [testCampaign]
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    try? eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                               for: testCampaign)
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                                  for: testCampaign)
                    }.toNot(throwError())
                }

                it("will succeed if only persistent events are required") {
                    let campaign = TestHelpers.generateCampaign(id: "test",
                                                                test: false, delay: 0,
                                                                maxImpressions: 1,
                                                                triggers: [
                                                                    Trigger(type: .event,
                                                                            eventType: .appStart,
                                                                            eventName: "appStartTest",
                                                                            attributes: [])
                        ]
                    )
                    campaignRepository.list = [campaign]
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent()], for: campaign)
                    }.toNot(throwError())
                }

                it("will succeed only once if only persistent events are required") {
                    let campaign = TestHelpers.generateCampaign(id: "test",
                                                                test: false, delay: 0,
                                                                maxImpressions: 1,
                                                                triggers: [
                                                                    Trigger(type: .event,
                                                                            eventType: .appStart,
                                                                            eventName: "appStartTest",
                                                                            attributes: [])
                        ]
                    )
                    campaignRepository.list = [campaign]
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    try? eventMatcher.removeSetOfMatchedEvents([AppStartEvent()], for: campaign)
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent()], for: campaign)
                    }.to(throwError(EventMatcherError.providedSetOfEventsHaveAlreadyBeenUsed))
                }

                it("won't remove persistent events") {
                    campaignRepository.list = [testCampaign]
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                                  for: testCampaign)
                    }.toNot(throwError())
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent()],
                                                                  for: testCampaign)
                    }.toNot(throwError())
                    // this case doesn't make sense as a use case but it's the only way
                    // to check for existence of AppStartEvent() in EventMather.persistentEvents list
                    // without exposing properties
                }
            }

            it("will properly match persistent events") {
                campaignRepository.list = [testCampaign]
                eventMatcher.matchAndStore(event: AppStartEvent())
                let events = eventMatcher.matchedEvents(for: testCampaign)
                expect(events).to(contain(AppStartEvent()))
            }

            it("will properly match non-persistent events") {
                campaignRepository.list = [testCampaign]
                eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                let events = eventMatcher.matchedEvents(for: testCampaign)
                expect(events).to(contain(LoginSuccessfulEvent()))
            }

            context("when calling containsAllMatchedEvents") {
                beforeEach {
                    campaignRepository.list = [testCampaign]
                }

                it("will return true if all required events were stored") {
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    expect(eventMatcher.containsAllMatchedEvents(for: testCampaign)).to(beTrue())
                }

                it("will return true if more events than required were stored") {
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: PurchaseSuccessfulEvent())
                    expect(eventMatcher.containsAllMatchedEvents(for: testCampaign)).to(beTrue())
                }

                it("will return false if not all required events were stored") {
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    expect(eventMatcher.containsAllMatchedEvents(for: testCampaign)).to(beFalse())
                }

                it("will return false if none of required events were stored") {
                    expect(eventMatcher.containsAllMatchedEvents(for: testCampaign)).to(beFalse())
                }

                it("will return false campaign has no triggers (which is an invalid state)") {
                    let campaign = TestHelpers.generateCampaign(id: "test",
                                                                test: false, delay: 0,
                                                                maxImpressions: 1,
                                                                triggers: [])
                    campaignRepository.list = [campaign]
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    expect(eventMatcher.containsAllMatchedEvents(for: campaign)).to(beFalse())
                }
            }
        }
    }
}
