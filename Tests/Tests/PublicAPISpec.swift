import UIKit
import Quick
import Nimble
#if canImport(RSDKUtilsMain)
import class RSDKUtilsMain.TypedDependencyManager // SPM version
#else
import class RSDKUtils.TypedDependencyManager
#endif
@testable import RInAppMessaging

class PublicAPISpec: QuickSpec {

    override func spec() {

        let userDefaults = UserDefaults(suiteName: "PublicAPISpec")!
        var eventMatcher: EventMatcherSpy!
        var accountRepository: AccountRepositoryType!
        var router: RouterType!
        var messageMixerService: MessageMixerServiceMock!
        var campaignsListManager: CampaignsListManagerType!
        var campaignRepository: CampaignRepositoryType!
        var configurationManager: ConfigurationManagerMock!
        var dataCache: UserDataCache!
        var contextVerifier: ContextVerifier!
        var errorReceiver: ErrorReceiver!

        func mockContainer() -> TypedDependencyManager.Container {
            return TypedDependencyManager.Container([
                TypedDependencyManager.ContainerElement(type: DisplayPermissionServiceType.self, factory: { DisplayPermissionServiceMock() }),
                TypedDependencyManager.ContainerElement(type: ConfigurationManagerType.self, factory: { configurationManager }),
                TypedDependencyManager.ContainerElement(type: MessageMixerServiceType.self, factory: { messageMixerService }),
                TypedDependencyManager.ContainerElement(type: EventMatcherType.self, factory: { eventMatcher }),
                TypedDependencyManager.ContainerElement(type: UserDataCacheable.self, factory: { dataCache })
            ])
        }

        func reinitializeSDK(onDependencyResolved: (() -> Void)? = nil) {
            let dependencyManager = TypedDependencyManager()
            dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager))
            dependencyManager.appendContainer(mockContainer())
            configurationManager = ConfigurationManagerMock()
            messageMixerService = MessageMixerServiceMock()
            dataCache = UserDataCache(userDefaults: userDefaults)
            eventMatcher = EventMatcherSpy(
                campaignRepository: dependencyManager.resolve(type: CampaignRepositoryType.self)!)
            accountRepository = dependencyManager.resolve(type: AccountRepositoryType.self)
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

        func waitForCache() {
            waitUntil { cacheSaved in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    cacheSaved()
                }
            }
        }

        beforeEach {
            reinitializeSDK()
            contextVerifier = ContextVerifier()
            RInAppMessaging.onVerifyContext = { contexts, campaignTitle in
                contextVerifier.onVerifyContext(contexts: contexts, campaignTitle: campaignTitle)
            }
            errorReceiver = ErrorReceiver()
            RInAppMessaging.errorCallback = { error in
                errorReceiver.inAppMessagingDidReturnError(error)
            }
            // wait for initialization to finish
            expect(RInAppMessaging.initializedModule).toEventuallyNot(beNil())
        }

        afterEach {
            RInAppMessaging.deinitializeModule()
            RInAppMessaging.onVerifyContext = nil
            RInAppMessaging.errorCallback = nil
            UserDefaults.standard.removePersistentDomain(forName: "PublicAPISpec")
            UIApplication.shared.getKeyWindow()?.subviews
                .filter { $0 is BaseView }
                .forEach { $0.removeFromSuperview() }
        }

        describe("RInAppMessaging") {

            it("will not crash if api methods are called prior to configure()") {
                RInAppMessaging.deinitializeModule()
                expect(RInAppMessaging.initializedModule).to(beNil())

                RInAppMessaging.onVerifyContext = { _, _ in
                    true
                }
                RInAppMessaging.accessibilityCompatibleDisplay = true
                RInAppMessaging.closeMessage(clearQueuedCampaigns: true)
                RInAppMessaging.logEvent(LoginSuccessfulEvent())
                RInAppMessaging.registerPreference(UserInfoProviderMock())
            }

            it("will send an error if api methods are called prior to configure()") {
                RInAppMessaging.deinitializeModule()
                expect(RInAppMessaging.initializedModule).to(beNil())
                errorReceiver = ErrorReceiver()

                RInAppMessaging.closeMessage(clearQueuedCampaigns: true) // 1st error sent
                RInAppMessaging.logEvent(LoginSuccessfulEvent()) // 2nd error sent
                expect(errorReceiver.totalErrorNumber).toEventually(equal(2))
            }

            it("won't reinitialize module if config was called more than once") {
                let expectedModule = RInAppMessaging.initializedModule
                RInAppMessaging.configure()
                expect(RInAppMessaging.initializedModule).toAfterTimeout(beIdenticalTo(expectedModule))
            }

            it("will register userInfoProvider when registerPreference() is called") {
                let userInfoProvider = UserInfoProviderMock()
                userInfoProvider.userID = "userID"
                userInfoProvider.idTrackingIdentifier = "tracking-id"

                RInAppMessaging.registerPreference(userInfoProvider)
                expect(accountRepository.userInfoProvider).toEventually(beIdenticalTo(userInfoProvider))
            }

            it("will log event when logEvent is called") {
                let event = AppStartEvent()
                RInAppMessaging.logEvent(event)
                expect(eventMatcher.loggedEvents).toEventually(contain(event))
            }

            it("will pass internal errors to errorCallback") {
                messageMixerService.mockedError = .invalidConfiguration
                campaignsListManager.refreshList()

                // errorReceiver is updated inside errorCallback
                expect(errorReceiver.returnedError?.domain).toEventually(
                    equal("InAppMessaging.CampaignsListManager"))
                expect(errorReceiver.returnedError?.localizedDescription).toEventually(
                    equal("InAppMessaging: Error retrieving InAppMessaging Mixer Server URL"))
            }

            it("will set accessibilityCompatibleDisplay flag in Router") {
                RInAppMessaging.accessibilityCompatibleDisplay = true
                expect(router.accessibilityCompatibleDisplay).toAfterTimeout(beTrue(), timeout: 0.2)
                RInAppMessaging.accessibilityCompatibleDisplay = false
                expect(router.accessibilityCompatibleDisplay).toEventually(beFalse())
            }

            it("won't send any events until configuration has finished") {
                RInAppMessaging.deinitializeModule()
                var resume: (() -> Void)!
                reinitializeSDK(onDependencyResolved: {
                    resume = messageMixerService.suspendNextPingAndWaitForSignal()
                })
                RInAppMessaging.logEvent(LoginSuccessfulEvent())
                expect(eventMatcher.loggedEvents).toAfterTimeout(beEmpty())
                resume()
                expect(eventMatcher.loggedEvents).toEventually(haveCount(1))
            }

            // This test checks if events logged after getConfig() failure (bufferedEvents)
            // are re-logged properly when retried getConfig request succeeds.
            // If buffered events satisfy all campaign triggers, for example 3 times,
            // then that campaign should be displayed 3 times (if maxImpression allows it).
            // This test also checks if campaigns are queued properly (respecting impressionsLeft value)
            // when multiple events are logged in a very short time.
            it("will display campaign 2 times for matching 'buffered' events") {
                RInAppMessaging.deinitializeModule()
                var resumeConfig: (() -> Void)!
                var configCalled = false
                reinitializeSDK(onDependencyResolved: {
                    resumeConfig = configurationManager.prepareRetryDelayAndWaitForSignal()
                    configurationManager.fetchCalledClosure = {
                        configCalled = true
                    }
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

                expect(configCalled).toEventually(beTrue())
                expect(eventMatcher.loggedEvents).to(beEmpty())
                resumeConfig()
                expect(eventMatcher.loggedEvents).toEventually(haveCount(3))

                expect(UIApplication.shared.getKeyWindow()?.subviews).toEventually(containElementSatisfying({
                    if let view = $0 as? BaseView {
                        view.dismiss()
                        return true
                    }
                    return false
                }))
                expect(UIApplication.shared.getKeyWindow()?.subviews).toEventually(containElementSatisfying({
                    if let view = $0 as? BaseView {
                        view.dismiss()
                        return true
                    }
                    return false
                }))
                // 3rd event is ignored because maxImpressions = 2
                expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toAfterTimeout(beNil())
            }

            it("will not count an impression if message wasn't closed") {
                generateAndDisplayLoginCampaigns(count: 1, addContexts: false)
                let campaign = campaignRepository.list[0]
                expect(campaign.impressionsLeft).to(equal(campaign.data.maxImpressions))
                expect(UIApplication.shared.getKeyWindow()?.subviews).toEventually(containElementSatisfying({
                    if let view = $0 as? BaseView {
                        expect(campaign).to(equal(view.basePresenter.campaign))
                        return true
                    }
                    return false
                }))
                let updatedCampaign = campaignRepository.list[0]
                expect(updatedCampaign.impressionsLeft).to(equal(updatedCampaign.data.maxImpressions))
            }

            context("when calling closeMessage") {

                it("will remove displayed campaign's view from hierarchy") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toEventuallyNot(beNil())
                    RInAppMessaging.closeMessage()
                    expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toEventually(beNil())
                }

                it("will not decrement impressionsLeft in closed campaign") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toEventuallyNot(beNil())
                    expect(campaignRepository.list.first?.impressionsLeft).to(equal(2))
                    RInAppMessaging.closeMessage()
                    expect(campaignRepository.list.first?.impressionsLeft).toAfterTimeout(equal(2))
                }
            }

            context("onVerifyContext") {

                it("will not call the method if there are no contexts") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(contextVerifier.onVerifyContextCallCount).toAfterTimeout(equal(0))
                }

                it("will call the method just before showing a message") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: true)

                    expect(contextVerifier.onVerifyContextCallCount).toEventually(equal(1))
                }

                it("will show a message if the method returned true") {
                    contextVerifier.shouldShowCampaign = true
                    generateAndDisplayLoginCampaigns(count: 2, addContexts: true)

                    expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toEventuallyNot(beNil())
                    UIApplication.shared.getKeyWindow()?.findIAMViewSubview()?.dismiss()
                    expect(contextVerifier.onVerifyContextCallCount).toEventually(equal(2))
                }

                it("will not show a message if the method returned false") {
                    contextVerifier.shouldShowCampaign = false
                    generateAndDisplayLoginCampaigns(count: 2, addContexts: true)

                    expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toAfterTimeout(beNil())
                    expect(contextVerifier.onVerifyContextCallCount).to(equal(2))
                }

                it("will call the method before showing a message with proper parameters") {
                    contextVerifier.shouldShowCampaign = true
                    messageMixerService.mockedResponse = PingResponse(
                        nextPingMilliseconds: Int.max,
                        currentPingMilliseconds: 0,
                        data: [
                            TestHelpers.generateCampaign(id: "1",
                                                         title: "[ctx1][ctx2] title",
                                                         triggers: [
                                                            Trigger(type: .event,
                                                                    eventType: .loginSuccessful,
                                                                    eventName: "e1",
                                                                    attributes: [])])])
                    campaignsListManager.refreshList()
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(contextVerifier.onVerifyContextCallParameters?.title).toEventually(equal("[ctx1][ctx2] title"), timeout: .seconds(2))
                    expect(contextVerifier.onVerifyContextCallParameters?.contexts)
                        .toEventually(contain(["ctx1", "ctx2"]), timeout: .seconds(2))
                }
            }

            context("caching") {

                it("will show a message if impressionsLeft was greater than 0 in the last session") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toEventuallyNot(beNil())
                    UIApplication.shared.getKeyWindow()?.findIAMViewSubview()?.dismiss()
                    waitForCache()

                    RInAppMessaging.deinitializeModule()
                    reinitializeSDK()
                    expect(campaignRepository.list).to(haveCount(1))
                    expect(campaignRepository.list.first?.impressionsLeft).to(equal(1))
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toEventuallyNot(beNil())
                }

                it("will not show a message if impressionsLeft was 0 in the last session") {
                    let mockedResponse = PingResponse(
                        nextPingMilliseconds: Int.max,
                        currentPingMilliseconds: 0,
                        data: [TestHelpers.generateCampaign(id: "test", maxImpressions: 1, delay: 100, test: false,
                                                            triggers: [Trigger(type: .event, eventType: .loginSuccessful,
                                                                               eventName: "e1", attributes: [])])])
                    messageMixerService.mockedResponse = mockedResponse
                    campaignsListManager.refreshList()
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toEventuallyNot(beNil())
                    UIApplication.shared.getKeyWindow()?.findIAMViewSubview()?.dismiss()
                    waitForCache()

                    RInAppMessaging.deinitializeModule()
                    reinitializeSDK()
                    messageMixerService.mockedResponse = mockedResponse
                    campaignsListManager.refreshList()
                    expect(campaignRepository.list.first?.impressionsLeft).to(equal(0))
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toAfterTimeout(beNil())
                }

                it("will not show a message if user opted out from it in the last session") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(UIApplication.shared.getKeyWindow()?.subviews).toEventually(containElementSatisfying({
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

                    expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toAfterTimeout(beNil())
                }

                // As it may contain outdated information (especially after logout)
                it("will not transfer cached data (sync) from anonymous user") {
                    messageMixerService.mockedResponse = TestHelpers.MockResponse.withGeneratedCampaigns(
                        count: 1, test: false, delay: 100, maxImpressions: 2, addContexts: false,
                        triggers: [Trigger(type: .event,
                                           eventType: .loginSuccessful,
                                           eventName: "e1",
                                           attributes: [])])
                    RInAppMessaging.registerPreference(UserInfoProviderMock()) // anonymous user
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toEventuallyNot(beNil())
                    UIApplication.shared.getKeyWindow()?.findIAMViewSubview()?.dismiss()
                    expect(dataCache.getUserData(identifiers: [])?.campaignData?.first?.impressionsLeft)
                        .toEventually(equal(1))

                    let aUser = UserInfoProviderMock()
                    aUser.userID = "user"
                    RInAppMessaging.registerPreference(aUser)
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

                    let emptyUser = UserInfoProviderMock()
                    emptyUser.userID = ""
                    RInAppMessaging.registerPreference(emptyUser)
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toEventuallyNot(beNil())
                    UIApplication.shared.getKeyWindow()?.findIAMViewSubview()?.dismiss()
                    expect(dataCache.getUserData(identifiers: [UserIdentifier(type: .userId, identifier: "")])?.campaignData?.first?.impressionsLeft)
                        .toEventually(equal(1))

                    let aUser = UserInfoProviderMock()
                    aUser.userID = "user"
                    RInAppMessaging.registerPreference(aUser)
                    let identifiers = [UserIdentifier(type: .userId, identifier: "user")]
                    expect(dataCache.getUserData(identifiers: identifiers)?.campaignData?.first?.impressionsLeft)
                        .toEventually(equal(2)) // nil -> 2
                }
            }
        }
    }
}

private class ErrorReceiver {
    private(set) var returnedError: NSError?
    private(set) var totalErrorNumber = 0
    func inAppMessagingDidReturnError(_ error: NSError) {
        totalErrorNumber += 1
        returnedError = error
    }
}

private class ContextVerifier {
    var onVerifyContextCallCount = 0
    var shouldShowCampaign = true
    var onVerifyContextCallParameters: (title: String, contexts: [String])?

    func onVerifyContext(contexts: [String], campaignTitle: String) -> Bool {
        onVerifyContextCallCount += 1
        onVerifyContextCallParameters = (campaignTitle, contexts)
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
