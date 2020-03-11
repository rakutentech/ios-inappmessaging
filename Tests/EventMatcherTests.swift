import Quick
import Nimble
@testable import RInAppMessaging

class EventMatcherTests: QuickSpec {

    override func spec() {

        describe("EventMatcher") {

            var campaignRepository: CampaignRepositoryMock!
            var eventMatcher: EventMatcher!

            beforeEach {
                campaignRepository = CampaignRepositoryMock()
                eventMatcher = EventMatcher(campaignRepository: campaignRepository)
            }

            context("when removing events") {
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
        }
    }
}

private class CampaignRepositoryMock: CampaignRepositoryType {
    var list: [Campaign] = []
    var resourcesToLock: [LockableResource] = []
    var lastSyncInMilliseconds: Int64?

    func syncWith(list: [Campaign], timestampMilliseconds: Int64) { }
    func optOutCampaign(_ campaign: Campaign) -> Campaign? { return nil }
    func decrementImpressionsLeftInCampaign(_ campaign: Campaign) -> Campaign? { return nil }
}
