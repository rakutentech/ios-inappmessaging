import Quick
import Nimble
@testable import RInAppMessaging

// swiftlint:disable force_try
class EventMatcherSpec: QuickSpec {

    override func spec() {

        describe("EventMatcher") {

            let testCampaign = TestHelpers.generateCampaign(
                id: "test",
                triggers: [
                    Trigger(type: .event,
                            eventType: .appStart,
                            eventName: "appStartTest",
                            attributes: []),
                    Trigger(type: .event,
                            eventType: .loginSuccessful,
                            eventName: "loginSuccessfulTest",
                            attributes: []),
                    Trigger(type: .event,
                            eventType: .custom,
                            eventName: "customEventTest",
                            attributes: [])
                ]
            )
            let testCampaignCustom = TestHelpers.generateCampaign(
                id: "test",
                triggers: [
                    Trigger(type: .event,
                            eventType: .custom,
                            eventName: "customEvent",
                            attributes: [
                                TriggerAttribute(name: "int",
                                                 value: "1",
                                                 type: .integer,
                                                 operatorType: .greaterThan)])
                ]
            )
            let persistentEventOnlyCampaign = TestHelpers.generateCampaign(id: "test",
                                                                           maxImpressions: 2,
                                                                           triggers: [
                                                                            Trigger(type: .event,
                                                                                    eventType: .appStart,
                                                                                    eventName: "appStartTest",
                                                                                    attributes: [])
                ]
            )
            let testTooltip = TestHelpers.generateTooltip(
                id: "test",
                isTest: false,
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
                    let customEvent = CustomEvent(withName: "customEventTest", withCustomAttributes: nil)
                    let customEventToRemove = CustomEvent(withName: "customEventToRemove", withCustomAttributes: nil)
                    campaignRepository.list = [testCampaign]
                    eventMatcher.matchAndStore(event: customEvent)
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([customEventToRemove],
                                                                  for: testCampaign)
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

                it("will throw error if persistent event for given campaign wasn't found") {
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent()], for: testCampaign)
                    }.to(throwError(EventMatcherError.couldntFindRequestedSetOfEvents))
                }

                it("will not persist normal events") {
                    campaignRepository.list = [testCampaign]
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    try! eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                               for: testCampaign)
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                                  for: testCampaign)
                    }.to(throwError(EventMatcherError.couldntFindRequestedSetOfEvents))
                }

                it("will succeed if all events are found") {
                    campaignRepository.list = [testCampaign]
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                                  for: testCampaign)
                    }.toNot(throwError())
                }

                it("will remove only one 'copy' of non-persistent event") {
                    campaignRepository.list = [testCampaign]
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: AppStartEvent())

                    try! eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                                for: testCampaign)
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                                  for: testCampaign)
                    }.toNot(throwError())
                }

                it("will not succeed if one of requested events doesn't match given campaign") {
                    campaignRepository.list = [testCampaign] // requires only Login and AppStart events
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    eventMatcher.matchAndStore(event: PurchaseSuccessfulEvent())
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent(), PurchaseSuccessfulEvent()],
                                                                  for: testCampaign)
                    }.to(throwError(EventMatcherError.couldntFindRequestedSetOfEvents))
                }

                it("will remove only matching custom event") {
                    campaignRepository.list = [testCampaignCustom]
                    eventMatcher.matchAndStore(
                        event: CustomEvent(withName: "customEvent",
                                           withCustomAttributes: [CustomAttribute(withKeyName: "int", withIntValue: 1)]))
                    eventMatcher.matchAndStore(
                        event: CustomEvent(withName: "customEvent",
                                           withCustomAttributes: [CustomAttribute(withKeyName: "int", withIntValue: 10)]))
                    eventMatcher.matchAndStore(
                        event: CustomEvent(withName: "customEvent",
                                           withCustomAttributes: [CustomAttribute(withKeyName: "int", withIntValue: 1)]))
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([
                            CustomEvent(withName: "customEvent",
                                        withCustomAttributes: [CustomAttribute(withKeyName: "int", withIntValue: 10)])],
                            for: testCampaignCustom)
                    }.toNot(throwError(EventMatcherError.couldntFindRequestedSetOfEvents))

                    expect(eventMatcher.matchedEvents(for: testCampaignCustom))
                        .toNot(containElementSatisfying({
                            ($0 as? CustomEvent)?.customAttributes?.first?.value as? Int == 10
                        })
                    )
                }

                it("will succeed again without need for persistent event to be logged") {
                    campaignRepository.list = [testCampaign]
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    try! eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                               for: testCampaign)
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent(), LoginSuccessfulEvent()],
                                                                  for: testCampaign)
                    }.toNot(throwError())
                }

                it("will succeed if only persistent events are required") {
                    campaignRepository.list = [persistentEventOnlyCampaign]
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent()], for: persistentEventOnlyCampaign)
                    }.toNot(throwError())
                }

                it("will succeed only once if only persistent events are required") {
                    campaignRepository.list = [persistentEventOnlyCampaign]
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    try! eventMatcher.removeSetOfMatchedEvents([AppStartEvent()], for: persistentEventOnlyCampaign)
                    expect {
                        try eventMatcher.removeSetOfMatchedEvents([AppStartEvent()], for: persistentEventOnlyCampaign)
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

            it("will not match any event with campaign that has no triggers") {
                let testCampaignWithoutTrigger = TestHelpers.generateCampaign(
                    id: "test"
                )
                campaignRepository.list = [testCampaignWithoutTrigger]
                eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                let events = eventMatcher.matchedEvents(for: testCampaignWithoutTrigger)
                expect(events).to(beEmpty())
            }

            it("will properly match non-persistent events") {
                campaignRepository.list = [testCampaign]
                eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                let events = eventMatcher.matchedEvents(for: testCampaign)
                expect(events).to(contain(LoginSuccessfulEvent()))
            }

            it("will not match ViewAppearedEvent to a campaign") {
                campaignRepository.list = [testCampaign]
                eventMatcher.matchAndStore(event: ViewAppearedEvent(viewIdentifier: TooltipViewIdentifierMock))
                let events = eventMatcher.matchedEvents(for: testCampaign)
                expect(events).to(beEmpty())
            }

            it("will match ViewAppearedEvent to a tooltip") {
                campaignRepository.list = [testTooltip]
                eventMatcher.matchAndStore(event: ViewAppearedEvent(viewIdentifier: TooltipViewIdentifierMock))
                let events = eventMatcher.matchedEvents(for: testCampaign)
                expect(events).to(contain(ViewAppearedEvent(viewIdentifier: TooltipViewIdentifierMock)))
            }

            context("when calling containsAllMatchedEvents") {
                beforeEach {
                    campaignRepository.list = [testCampaign]
                }

                it("will return true if all required events were stored") {
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: CustomEvent(withName: "customEventTest", withCustomAttributes: []))
                    expect(eventMatcher.containsAllRequiredEvents(for: testCampaign)).to(beTrue())
                }

                it("will return true if more events than required were stored") {
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: PurchaseSuccessfulEvent())
                    eventMatcher.matchAndStore(event: CustomEvent(withName: "customEventTest", withCustomAttributes: []))
                    expect(eventMatcher.containsAllRequiredEvents(for: testCampaign)).to(beTrue())
                }

                it("will return false if not all required events were stored") {
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    expect(eventMatcher.containsAllRequiredEvents(for: testCampaign)).to(beFalse())
                }

                it("will return false if none of required events were stored") {
                    expect(eventMatcher.containsAllRequiredEvents(for: testCampaign)).to(beFalse())
                }

                it("will return false campaign has no triggers (which is an invalid state)") {
                    let campaign = TestHelpers.generateCampaign(id: "test", triggers: [])
                    campaignRepository.list = [campaign]
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    expect(eventMatcher.containsAllRequiredEvents(for: campaign)).to(beFalse())
                }

                context("with a tooltip") {
                    beforeEach {
                        campaignRepository.list = [testTooltip]
                    }

                    it("will return false if has all events matching triggers but without matching ViewAppearedEvent") {
                        eventMatcher.matchAndStore(event: AppStartEvent())
                        eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                        expect(eventMatcher.containsAllRequiredEvents(for: testTooltip)).to(beFalse())
                    }

                    it("will return false if has matching ViewAppearedEvent but without events matching triggers") {
                        eventMatcher.matchAndStore(event: ViewAppearedEvent(viewIdentifier: TooltipViewIdentifierMock))
                        expect(eventMatcher.containsAllRequiredEvents(for: testTooltip)).to(beFalse())
                    }

                    it("will return true if all required events are stored") {
                        eventMatcher.matchAndStore(event: AppStartEvent())
                        eventMatcher.matchAndStore(event: ViewAppearedEvent(viewIdentifier: TooltipViewIdentifierMock))
                        eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                        expect(eventMatcher.containsAllRequiredEvents(for: testTooltip)).to(beTrue())
                    }
                }
            }

            context("when calling clearNonPersistentEvents") {

                it("will clear all matched non-persistent events") {
                    campaignRepository.list = [testCampaign]
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    expect(eventMatcher.matchedEvents(for: testCampaign)).toNot(beEmpty())

                    eventMatcher.clearNonPersistentEvents()
                    expect(eventMatcher.matchedEvents(for: testCampaign)).to(beEmpty())
                }

                it("will not clear persistent events") {
                    campaignRepository.list = [testCampaign]
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    expect(eventMatcher.matchedEvents(for: testCampaign)).toNot(beEmpty())

                    eventMatcher.clearNonPersistentEvents()
                    expect(eventMatcher.matchedEvents(for: testCampaign)).toNot(beEmpty())
                }

                context("tooltip case") {
                    it("will clear all matched non-persistent events") {
                        campaignRepository.list = [testTooltip]
                        eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                        eventMatcher.matchAndStore(event: ViewAppearedEvent(viewIdentifier: TooltipViewIdentifierMock))
                        expect(eventMatcher.matchedEvents(for: testTooltip)).toNot(beEmpty())

                        eventMatcher.clearNonPersistentEvents()
                        expect(eventMatcher.matchedEvents(for: testTooltip)).to(beEmpty())
                    }

                    it("will not clear persistent events") {
                        campaignRepository.list = [testTooltip]
                        eventMatcher.matchAndStore(event: AppStartEvent())
                        expect(eventMatcher.matchedEvents(for: testTooltip)).toNot(beEmpty())

                        eventMatcher.clearNonPersistentEvents()
                        expect(eventMatcher.matchedEvents(for: testTooltip)).toNot(beEmpty())
                    }
                }
            }
        }
    }
}
