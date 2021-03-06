import Quick
import Nimble
@testable import RInAppMessaging

class PublicAPISpec: QuickSpec {

    override func spec() {

        let userDefaults = UserDefaults(suiteName: "PublicAPISpec")!
        var eventMatcher: EventMatcherSpy!
        var preferenceRepository: IAMPreferenceRepository!
        var router: RouterType!
        var messageMixerService: MessageMixerServiceMock!
        var campaignsListManager: CampaignsListManagerType!
        var campaignRepository: CampaignRepositoryType!
        var configurationManager: ConfigurationManagerMock!
        var dataCache: UserDataCache!
        var delegate: Delegate!

        func mockContainer() -> DependencyManager.Container {
            return DependencyManager.Container([
                DependencyManager.ContainerElement(type: DisplayPermissionServiceType.self, factory: { DisplayPermissionServiceMock() }),
                DependencyManager.ContainerElement(type: ConfigurationManagerType.self, factory: { configurationManager }),
                DependencyManager.ContainerElement(type: MessageMixerServiceType.self, factory: { messageMixerService }),
                DependencyManager.ContainerElement(type: EventMatcherType.self, factory: { eventMatcher }),
                DependencyManager.ContainerElement(type: UserDataCacheable.self, factory: { dataCache })
            ])
        }

        func reinitializeSDK(onDependencyResolved: (() -> Void)? = nil) {
            let dependencyManager = DependencyManager()
            dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager))
            dependencyManager.appendContainer(mockContainer())
            configurationManager = ConfigurationManagerMock()
            messageMixerService = MessageMixerServiceMock()
            dataCache = UserDataCache(userDefaults: userDefaults)
            eventMatcher = EventMatcherSpy(
                campaignRepository: dependencyManager.resolve(type: CampaignRepositoryType.self)!)
            preferenceRepository = dependencyManager.resolve(type: IAMPreferenceRepository.self)
            router = dependencyManager.resolve(type: RouterType.self)!
            campaignsListManager = dependencyManager.resolve(type: CampaignsListManagerType.self)
            campaignRepository = dependencyManager.resolve(type: CampaignRepositoryType.self)
            onDependencyResolved?()
            RInAppMessaging.configure(dependencyManager: dependencyManager)
        }

        func generateAndDisplayLoginCampaigns(count: Int, addContexts: Bool) {
            messageMixerService.mockedResponse = TestHelpers.MockResponse.withGeneratedCampaigns(
                count: count, test: false, delay: 100, addContexts: addContexts,
                triggers: [Trigger(type: .event,
                                   eventType: .loginSuccessful,
                                   eventName: "e1",
                                   attributes: [])])
            campaignsListManager.refreshList()
            RInAppMessaging.logEvent(LoginSuccessfulEvent())
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
            UserDefaults.standard.removePersistentDomain(forName: "PublicAPISpec")
            UIApplication.shared.keyWindow?.subviews
                .filter { $0 is BaseView }
                .forEach { $0.removeFromSuperview() }
        }

        describe("RInAppMessaging") {

            it("will not crash if api methods are called prior to configure()") {
                RInAppMessaging.deinitializeModule()
                expect(RInAppMessaging.initializedModule).to(beNil())

                let errorDelegate = ErrorDelegate()
                RInAppMessaging.delegate = delegate
                RInAppMessaging.errorDelegate = errorDelegate
                RInAppMessaging.accessibilityCompatibleDisplay = true
                RInAppMessaging.closeMessage(clearQueuedCampaigns: true)
                RInAppMessaging.logEvent(LoginSuccessfulEvent())
                RInAppMessaging.registerPreference(IAMPreferenceBuilder().setUserId("user").build())
            }

            it("will send an error if api methods are called prior to configure()") {
                RInAppMessaging.deinitializeModule()
                expect(RInAppMessaging.initializedModule).to(beNil())

                let errorDelegate = ErrorDelegate()
                RInAppMessaging.errorDelegate = errorDelegate

                RInAppMessaging.closeMessage(clearQueuedCampaigns: true) // 1st error sent
                RInAppMessaging.logEvent(LoginSuccessfulEvent()) // 2nd error sent
                RInAppMessaging.registerPreference(IAMPreferenceBuilder().setUserId("user").build()) // 3rd error sent
                expect(errorDelegate.totalErrorNumber).toEventually(equal(3))
            }

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
                expect(router.accessibilityCompatibleDisplay).toAfterTimeout(beTrue())
                RInAppMessaging.accessibilityCompatibleDisplay = false
                expect(router.accessibilityCompatibleDisplay).toEventually(beFalse())
            }

            it("won't send any events until configuration has finished") {
                RInAppMessaging.deinitializeModule()
                reinitializeSDK(onDependencyResolved: {
                    messageMixerService.delay = 3.0
                })
                RInAppMessaging.logEvent(LoginSuccessfulEvent())
                expect(eventMatcher.loggedEvents).toAfterTimeout(beEmpty(), timeout: 1)
                expect(eventMatcher.loggedEvents).toEventually(haveCount(1),
                                                               timeout: .seconds(Int(messageMixerService.delay + 1)),
                                                               pollInterval: .milliseconds(500))
            }

            // This test checks if events logged after getConfig() failure (bufferedEvents)
            // are re-logged properly when retried getConfig request succeeds.
            // If buffered events can fill the set of campaign triggers, for example 3 times,
            // then that campaign should be displayed 3 times if maxImpression allows it.
            // This test also checks if campaigns are queued properly (respecting impressionsLeft value)
            // when multiple events are logged in very short time.
            it("will display campaign 2 times after first ping call for matching events that were logged after getConfig request failure") {
                RInAppMessaging.deinitializeModule()
                reinitializeSDK(onDependencyResolved: {
                    configurationManager.simulateRetryDelay = 1.0
                    messageMixerService.delay = 1.0
                    messageMixerService.mockedResponse = TestHelpers.MockResponse.withGeneratedCampaigns(
                        count: 1, test: false, delay: 100, maxImpressions: 2, addContexts: false,
                        triggers: [Trigger(type: .event,
                                           eventType: .loginSuccessful,
                                           eventName: "e1",
                                           attributes: [])])
                })
                RInAppMessaging.logEvent(LoginSuccessfulEvent())
                RInAppMessaging.logEvent(LoginSuccessfulEvent())
                RInAppMessaging.logEvent(LoginSuccessfulEvent())

                expect(UIApplication.shared.keyWindow?.subviews).toEventually(containElementSatisfying({
                    if let view = $0 as? BaseView {
                        view.dismiss()
                        return true
                    }
                    return false
                }), timeout: .seconds(3))
                expect(UIApplication.shared.keyWindow?.subviews).toEventually(containElementSatisfying({
                    if let view = $0 as? BaseView {
                        view.dismiss()
                        return true
                    }
                    return false
                }))
                expect(UIApplication.shared.keyWindow?.subviews).toAfterTimeoutNot(containElementSatisfying({
                    $0 is BaseView
                }))
            }

            context("when calling closeMessage") {

                it("will remove displayed campaign's view from hierarchy") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(UIApplication.shared.keyWindow?.subviews).toEventually(containElementSatisfying({
                        $0 is BaseView
                    }))
                    RInAppMessaging.closeMessage()
                    expect(UIApplication.shared.keyWindow?.subviews).toEventuallyNot(containElementSatisfying({
                        $0 is BaseView
                    }))
                }

                it("will restore/increment impressionsLeft in closed campaign") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(campaignRepository.list.first?.impressionsLeft).toEventually(equal(1))
                    RInAppMessaging.closeMessage()
                    expect(campaignRepository.list.first?.impressionsLeft).toEventually(equal(2))
                }
            }

            context("delegate") {

                it("will not call the method if there are no contexts") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(delegate.shouldShowCampaignCallCount).toAfterTimeout(equal(0))
                }

                it("will call the method just before showing a message") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: true)

                    expect(delegate.shouldShowCampaignCallCount).toEventually(equal(1))
                }

                it("will show a message if the method returned true") {
                    delegate.shouldShowCampaign = true
                    generateAndDisplayLoginCampaigns(count: 2, addContexts: true)

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
                    delegate.shouldShowCampaign = false
                    generateAndDisplayLoginCampaigns(count: 2, addContexts: true)

                    expect(UIApplication.shared.keyWindow?.subviews)
                        .toAfterTimeout(allPass({ !($0 is BaseView) }))
                    expect(delegate.shouldShowCampaignCallCount).toAfterTimeout(equal(2))
                }

                it("will call the method before showing a message with proper parameters") {
                    delegate.shouldShowCampaign = true
                    messageMixerService.mockedResponse = PingResponse(
                        nextPingMilliseconds: Int.max,
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

            context("caching") {
                afterEach {
                    UIApplication.shared.keyWindow?.subviews
                        .filter { $0 is BaseView }
                        .forEach { $0.removeFromSuperview() }
                }

                it("will show a message if impressionsLeft was greater than 0 in the last session") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(UIApplication.shared.keyWindow?.subviews).toEventually(containElementSatisfying({
                        if let view = $0 as? BaseView {
                            view.dismiss()
                            return true
                        }
                        return false
                    }))

                    RInAppMessaging.deinitializeModule()
                    reinitializeSDK()
                    expect(campaignRepository.list).to(haveCount(1))
                    expect(campaignRepository.list.first?.impressionsLeft).to(equal(1))
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(UIApplication.shared.keyWindow?.subviews).toEventually(containElementSatisfying({
                        $0 is BaseView
                    }))
                }

                it("will not show a message if impressionsLeft was 0 in the last session") {
                    let mockedResponse = PingResponse(
                        nextPingMilliseconds: Int.max,
                        currentPingMilliseconds: 0,
                        data: [TestHelpers.generateCampaign(id: "test", test: false, delay: 100, maxImpressions: 1,
                                                            triggers: [Trigger(type: .event, eventType: .loginSuccessful,
                                                                               eventName: "e1", attributes: [])])])
                    messageMixerService.mockedResponse = mockedResponse
                    campaignsListManager.refreshList()
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(UIApplication.shared.keyWindow?.subviews).toEventually(containElementSatisfying({
                        if let view = $0 as? BaseView {
                            view.dismiss()
                            return true
                        }
                        return false
                    }))

                    RInAppMessaging.deinitializeModule()
                    reinitializeSDK()
                    messageMixerService.mockedResponse = mockedResponse
                    campaignsListManager.refreshList()
                    expect(campaignRepository.list).to(haveCount(1))
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(UIApplication.shared.keyWindow?.subviews)
                        .toAfterTimeout(allPass({ !($0 is BaseView) }))
                }

                it("will not show a message if user opted out from it in the last session") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(UIApplication.shared.keyWindow?.subviews).toEventually(containElementSatisfying({
                        if let view = $0 as? BaseView {
                            view.basePresenter.optOutCampaign()
                            view.dismiss()
                            return true
                        }
                        return false
                    }))

                    RInAppMessaging.deinitializeModule()
                    reinitializeSDK()
                    expect(campaignRepository.list).to(haveCount(1))
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(UIApplication.shared.keyWindow?.subviews)
                        .toAfterTimeout(allPass({ !($0 is BaseView) }))
                }

                // As it may contain outdated information (especially after logout)
                it("will not transfer cached data (sync) from anonymous user") {
                    messageMixerService.mockedResponse = TestHelpers.MockResponse.withGeneratedCampaigns(
                        count: 1, test: false, delay: 100, maxImpressions: 2, addContexts: false,
                        triggers: [Trigger(type: .event,
                                           eventType: .loginSuccessful,
                                           eventName: "e1",
                                           attributes: [])])
                    RInAppMessaging.registerPreference(nil)
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())
                    expect(UIApplication.shared.keyWindow?.subviews).toEventually(containElementSatisfying({
                        $0 is BaseView
                    })) // wait
                    expect(dataCache.getUserData(identifiers: [])?.campaignData?.first?.impressionsLeft)
                        .to(equal(1))

                    RInAppMessaging.registerPreference(IAMPreferenceBuilder().setUserId("user").build())
                    let identifiers = [UserIdentifier(type: .userId, identifier: "user")]
                    expect(dataCache.getUserData(identifiers: identifiers)?.campaignData?.first?.impressionsLeft)
                        .toEventually(equal(2)) // nil -> 2
                }

                it("will not transfer cached data (sync) from empty user") {
                    messageMixerService.mockedResponse = TestHelpers.MockResponse.withGeneratedCampaigns(
                        count: 1, test: false, delay: 100, maxImpressions: 2, addContexts: false,
                        triggers: [Trigger(type: .event,
                                           eventType: .loginSuccessful,
                                           eventName: "e1",
                                           attributes: [])])
                    RInAppMessaging.registerPreference(IAMPreferenceBuilder().setUserId("").build())
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())
                    expect(UIApplication.shared.keyWindow?.subviews).toEventually(containElementSatisfying({
                        $0 is BaseView
                    })) // wait
                    expect(dataCache.getUserData(identifiers: [UserIdentifier(type: .userId, identifier: "")])?.campaignData?.first?.impressionsLeft)
                        .to(equal(1))

                    RInAppMessaging.registerPreference(IAMPreferenceBuilder().setUserId("user").build())
                    let identifiers = [UserIdentifier(type: .userId, identifier: "user")]
                    expect(dataCache.getUserData(identifiers: identifiers)?.campaignData?.first?.impressionsLeft)
                        .toEventually(equal(2)) // nil -> 2
                }
            }
        }
    }
}

private class ErrorDelegate: RInAppMessagingErrorDelegate {
    private(set) var returnedError: NSError?
    private(set) var totalErrorNumber = 0
    func inAppMessagingDidReturnError(_ error: NSError) {
        totalErrorNumber += 1
        returnedError = error
    }
}

private class Delegate: RInAppMessagingDelegate {
    var shouldShowCampaignCallCount = 0
    var shouldShowCampaign = true
    var shouldShowCampaignCallParameters: (title: String, contexts: [String])?

    func inAppMessagingShouldShowCampaignWithContexts(contexts: [String], campaignTitle: String) -> Bool {
        shouldShowCampaignCallCount += 1
        shouldShowCampaignCallParameters = (campaignTitle, contexts)
        return shouldShowCampaign
    }
}

private class EventMatcherSpy: EventMatcher {
    private(set) var loggedEvents = [Event]()

    override func matchAndStore(event: Event) {
        loggedEvents.append(event)
        super.matchAndStore(event: event)
    }
}
