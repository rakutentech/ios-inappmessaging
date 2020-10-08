import Quick
import Nimble
@testable import RInAppMessaging

class PublicAPITests: QuickSpec {

    override func spec() {

        var eventMatcher: EventMatcherSpy!
        var preferenceRepository: IAMPreferenceRepository!
        var router: RouterType!
        var messageMixerService: MessageMixerServiceMock!
        var campaignsListManager: CampaignsListManagerType!
        var delegate: Delegate!

        func mockContainer() -> DependencyManager.Container {
            return DependencyManager.Container([
                DependencyManager.ContainerElement(type: ConfigurationManagerType.self, factory: {
                    let manager = ConfigurationManagerMock()
                    manager.isConfigEnabled = true
                    return manager
                }),
                DependencyManager.ContainerElement(type: MessageMixerServiceType.self, factory: {
                    return messageMixerService
                }),
                DependencyManager.ContainerElement(type: EventMatcherType.self, factory: {
                    return eventMatcher
                })
            ])
        }

        func reinitializeSDK() {
            let dependencyManager = DependencyManager()
            dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager))
            messageMixerService = MessageMixerServiceMock()
            eventMatcher = EventMatcherSpy(
                campaignRepository: dependencyManager.resolve(type: CampaignRepositoryType.self)!)
            dependencyManager.appendContainer(mockContainer())
            preferenceRepository = dependencyManager.resolve(type: IAMPreferenceRepository.self)!
            router = dependencyManager.resolve(type: RouterType.self)!
            campaignsListManager = dependencyManager.resolve(type: CampaignsListManagerType.self)!
            RInAppMessaging.configure(dependencyManager: dependencyManager)
        }

        beforeEach {
            reinitializeSDK()
            delegate = Delegate()
            RInAppMessaging.delegate = delegate
            // wait for initialization to finish
            expect(RInAppMessaging.initializedModule).toEventuallyNot(beNil())
        }

        afterEach {
            RInAppMessaging.deinitializeModule()
        }

        describe("RInAppMessaging") {

            it("won't reinitialize module if config was called more than once") {
                let expectedModule = RInAppMessaging.initializedModule
                RInAppMessaging.configure()
                expect(RInAppMessaging.initializedModule).toAfterTimeout(beIdenticalTo(expectedModule))
            }

            it("will register preference when registerPreference() is called") {
                let preference = IAMPreferenceBuilder()
                    .setUserId("userID")
                    .setRakutenId("RID")
                    .build()
                RInAppMessaging.registerPreference(preference)
                expect(preferenceRepository.preference).toEventually(equal(preference))
            }

            it("will log event when logEvent is called") {
                let event = AppStartEvent()
                RInAppMessaging.logEvent(event)
                expect(eventMatcher.loggedEvents).toEventually(contain(event))
            }

            it("will post notification (RAT) when logEvent is called") {
                expect {
                    RInAppMessaging.logEvent(AppStartEvent())
                }.toEventually(postNotifications(containElementSatisfying({
                    $0.name == Notification.Name("com.rakuten.esd.sdk.events.custom")
                })))
            }

            it("will pass errors to errorDelegate") {
                let delegate = ErrorDelegate()
                RInAppMessaging.errorDelegate = delegate
                messageMixerService.mockedError = .invalidConfiguration
                campaignsListManager.refreshList()
                expect(delegate.returnedError?.domain).toEventually(
                    equal("InAppMessaging.CampaignsListManager"))
                expect(delegate.returnedError?.localizedDescription).toEventually(
                    equal("InAppMessaging: Error retrieving InAppMessaging Mixer Server URL"))
            }

            it("will set accessibilityCompatibleDisplay flag in Router") {
                RInAppMessaging.accessibilityCompatibleDisplay = true
                expect(router.accessibilityCompatibleDisplay).to(beTrue())
                RInAppMessaging.accessibilityCompatibleDisplay = false
                expect(router.accessibilityCompatibleDisplay).to(beFalse())
            }

            it("won't send any events until configuration has finished") {
                messageMixerService.delay = 3.0
                RInAppMessaging.deinitializeModule()
                reinitializeSDK()
                RInAppMessaging.logEvent(LoginSuccessfulEvent())
                expect(eventMatcher.loggedEvents).toAfterTimeout(beEmpty(), timeout: 1)
                expect(eventMatcher.loggedEvents).toEventually(haveCount(1),
                                                               timeout: .seconds(Int(messageMixerService.delay + 1)),
                                                               pollInterval: .milliseconds(500))
            }

            context("delegate") {
                afterEach {
                    UIApplication.shared.keyWindow?.subviews
                        .filter { $0 is BaseView }
                        .forEach { $0.removeFromSuperview() }
                }

                it("will not call the method if there are no contexts") {
                    messageMixerService.mockedResponse = TestHelpers.MockResponse.withGeneratedCampaigns(
                        count: 1, test: false, delay: 0, addContexts: false,
                        triggers: [Trigger(type: .event,
                                           eventType: .loginSuccessful,
                                           eventName: "e1",
                                           attributes: [])])
                    campaignsListManager.refreshList()
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(delegate.shouldShowCampaignCallCount).toAfterTimeout(equal(0))
                }

                it("will call the method just before showing a message") {
                    messageMixerService.mockedResponse = TestHelpers.MockResponse.withGeneratedCampaigns(
                        count: 1, test: false, delay: 0, addContexts: true,
                        triggers: [Trigger(type: .event,
                                           eventType: .loginSuccessful,
                                           eventName: "e1",
                                           attributes: [])])
                    campaignsListManager.refreshList()
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(delegate.shouldShowCampaignCallCount).toEventually(equal(1))
                }

                it("will show a message if the method returned true") {
                    delegate.shouldShowCampaignResult = true
                    messageMixerService.mockedResponse = TestHelpers.MockResponse.withGeneratedCampaigns(
                        count: 2, test: false, delay: 100, addContexts: true,
                        triggers: [Trigger(type: .event,
                                           eventType: .loginSuccessful,
                                           eventName: "e1",
                                           attributes: [])])
                    campaignsListManager.refreshList()
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(UIApplication.shared.keyWindow?.subviews).toEventually(containElementSatisfying({
                        if let view = $0 as? BaseView {
                            view.dismiss()
                            return true
                        }
                        return false
                    }))
                    expect(delegate.shouldShowCampaignCallCount).toEventually(equal(2))
                }

                it("will not show a message if the method returned false") {
                    delegate.shouldShowCampaignResult = false
                    messageMixerService.mockedResponse = TestHelpers.MockResponse.withGeneratedCampaigns(
                        count: 2, test: false, delay: 100, addContexts: true,
                        triggers: [Trigger(type: .event,
                                           eventType: .loginSuccessful,
                                           eventName: "e1",
                                           attributes: [])])
                    campaignsListManager.refreshList()
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(UIApplication.shared.keyWindow?.subviews)
                        .toAfterTimeout(allPass({ !($0 is BaseView) }))
                    expect(delegate.shouldShowCampaignCallCount).toAfterTimeout(equal(0))
                }

                it("will call the method before showing a message with proper parameters") {
                    delegate.shouldShowCampaignResult = true
                    messageMixerService.mockedResponse = PingResponse(
                        nextPingMilliseconds: 0,
                        currentPingMilliseconds: 0,
                        data: [
                            TestHelpers.generateCampaign(id: "1",
                                                         test: false,
                                                         delay: 0,
                                                         maxImpressions: 1,
                                                         title: "[ctx1][ctx2] title",
                                                         triggers: [
                                                            Trigger(type: .event,
                                                                    eventType: .loginSuccessful,
                                                                    eventName: "e1",
                                                                    attributes: [])])])
                    campaignsListManager.refreshList()
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(delegate.shouldShowCampaignCallParameters?.title).toEventually(equal("[ctx1][ctx2] title"), timeout: .seconds(2))
                    expect(delegate.shouldShowCampaignCallParameters?.contexts)
                        .toEventually(contain(["ctx1", "ctx2"]), timeout: .seconds(2))
                }
            }
        }
    }
}

private class ErrorDelegate: RInAppMessagingErrorDelegate {
    private(set) var returnedError: NSError?
    func inAppMessagingDidReturnError(_ error: NSError) {
        returnedError = error
    }
}

private class Delegate: RInAppMessagingDelegate {
    var shouldShowCampaignCallCount = 0
    var shouldShowCampaignResult = true
    var shouldShowCampaignCallParameters: (title: String, contexts: [String])?

    func inAppMessagingShouldShowCampaignsWithContexts(contexts: [String], campaignTitle: String) -> Bool {
        shouldShowCampaignCallCount += 1
        shouldShowCampaignCallParameters = (campaignTitle, contexts)
        return shouldShowCampaignResult
    }
}

private class EventMatcherSpy: EventMatcher {
    private(set) var loggedEvents = [Event]()

    override func matchAndStore(event: Event) {
        loggedEvents.append(event)
        super.matchAndStore(event: event)
    }
}
