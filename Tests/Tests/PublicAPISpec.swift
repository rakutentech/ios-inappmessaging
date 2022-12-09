import UIKit
import Quick
import Nimble
#if canImport(RSDKUtilsMain)
import class RSDKUtilsMain.TypedDependencyManager // SPM version
#else
import class RSDKUtils.TypedDependencyManager
#endif
@testable import RInAppMessaging

// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
class PublicAPISpec: QuickSpec {

    override func spec() {

        let defaultConfig = InAppMessagingModuleConfiguration(configURLString: nil,
                                                              subscriptionID: nil,
                                                              isTooltipFeatureEnabled: true)
        let tooltipTargetView = UIView(frame: CGRect(x: 100, y: 100, width: 10, height: 10))
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
        var configurationRepository: ConfigurationRepositoryType!

        func mockContainer() -> TypedDependencyManager.Container {
            return TypedDependencyManager.Container([
                TypedDependencyManager.ContainerElement(type: DisplayPermissionServiceType.self, factory: { DisplayPermissionServiceMock() }),
                TypedDependencyManager.ContainerElement(type: ConfigurationManagerType.self, factory: { configurationManager }),
                TypedDependencyManager.ContainerElement(type: MessageMixerServiceType.self, factory: { messageMixerService }),
                TypedDependencyManager.ContainerElement(type: EventMatcherType.self, factory: { eventMatcher }),
                TypedDependencyManager.ContainerElement(type: UserDataCacheable.self, factory: { dataCache })
            ])
        }

        func reinitializeSDK(waitForInit: Bool = true,
                             config: InAppMessagingModuleConfiguration = defaultConfig,
                             onDependenciesResolved: (() -> Void)? = nil) {
            let dependencyManager = TypedDependencyManager()
            dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager,
                                                                          configURL: URL(string: config.configURLString ?? "empty")!))
            dependencyManager.appendContainer(mockContainer())
            messageMixerService = MessageMixerServiceMock()
            dataCache = UserDataCache(userDefaults: userDefaults)
            eventMatcher = EventMatcherSpy(
                campaignRepository: dependencyManager.resolve(type: CampaignRepositoryType.self)!)
            accountRepository = dependencyManager.resolve(type: AccountRepositoryType.self)
            router = dependencyManager.resolve(type: RouterType.self)!
            campaignsListManager = dependencyManager.resolve(type: CampaignsListManagerType.self)
            campaignRepository = dependencyManager.resolve(type: CampaignRepositoryType.self)
            configurationRepository = dependencyManager.resolve(type: ConfigurationRepositoryType.self)
            configurationManager = ConfigurationManagerMock(configurationRepository: configurationRepository)
            onDependenciesResolved?()
            RInAppMessaging.configure(dependencyManager: dependencyManager,
                                      moduleConfig: config)
            if waitForInit {
                // wait for initialization to finish
                expect(RInAppMessaging.initializedModule).toEventuallyNot(beNil())
            }
        }

        func generateAndDisplayLoginCampaigns(count: Int, addContexts: Bool) {
            messageMixerService.mockedResponse = TestHelpers.MockResponse.withGeneratedCampaigns(
                count: count, test: false, delay: 100, addContexts: addContexts,
                triggers: [Trigger.loginEventTrigger])
            campaignsListManager.refreshList()
            RInAppMessaging.logEvent(LoginSuccessfulEvent())
        }

        func generateAndDisplayLoginTooltip(uiElementIdentifier: String, addContexts: Bool) {
            messageMixerService.mockedResponse = TestHelpers.MockResponse.withGeneratedTooltip(
                uiElementIdentifier: uiElementIdentifier, addContexts: addContexts,
                triggers: [Trigger.loginEventTrigger])
            campaignsListManager.refreshList()
            tooltipTargetView.accessibilityIdentifier = uiElementIdentifier
            UIApplication.shared.getKeyWindow()?.addSubview(tooltipTargetView)
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
        }

        afterEach {
            RInAppMessaging.deinitializeModule()
            RInAppMessaging.onVerifyContext = nil
            RInAppMessaging.errorCallback = nil
            UserDefaults.standard.removePersistentDomain(forName: "PublicAPISpec")
            UIApplication.shared.getKeyWindow()?.findIAMView()?.removeFromSuperview()
            UIApplication.shared.getKeyWindow()?.findTooltipView()?.removeFromSuperview()
            tooltipTargetView.removeFromSuperview()
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
                RInAppMessaging.registerPreference(UserInfoProviderMock()) // 3rd error sent
                expect(errorReceiver.totalErrorNumber).toEventually(equal(3))
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
                reinitializeSDK(onDependenciesResolved: {
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
                reinitializeSDK(onDependenciesResolved: {
                    resumeConfig = configurationManager.prepareRetryDelayAndWaitForSignal()
                    configurationManager.fetchCalledClosure = {
                        configCalled = true
                    }
                    messageMixerService.mockedResponse = TestHelpers.MockResponse.withGeneratedCampaigns(
                        count: 1, test: false, delay: 100, maxImpressions: 2, addContexts: false,
                        triggers: [Trigger.loginEventTrigger])
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
                expect(UIApplication.shared.getKeyWindow()?.findIAMView()).toAfterTimeout(beNil())
            }

            context("when calling configure()") {

                it("won't reinitialize module if configure() was called more than once") {
                    let expectedModule = RInAppMessaging.initializedModule
                    RInAppMessaging.configure()
                    expect(RInAppMessaging.initializedModule).toAfterTimeout(beIdenticalTo(expectedModule))
                }

                it("will deinitialize module when completion was called with shouldDeinit = true") {
                    RInAppMessaging.deinitializeModule()
                    expect(RInAppMessaging.initializedModule).to(beNil())

                    var resumeRetry: (() -> Void)!
                    reinitializeSDK(waitForInit: false) {
                        resumeRetry = configurationManager.prepareRetryDelayAndWaitForSignal() // added delay to capture initialized object
                        configurationManager.rolloutPercentage = 0 // triggers deinit
                    }
                    expect(RInAppMessaging.initializedModule).toEventuallyNot(beNil())
                    weak var initializedModule = RInAppMessaging.initializedModule
                    resumeRetry()
                    expect(RInAppMessaging.initializedModule).toEventually(beNil())
                    expect(initializedModule).to(beNil())
                }

                // NOTE: configURL setting tests are omitted because in unit test environment the value is always set to "https://config.test"
                context("when subscriptionID argument is set") {
                    it("should set the same value in ConfigurationRepository (override Info.plist setting)") {
                        RInAppMessaging.deinitializeModule()
                        reinitializeSDK(config: InAppMessagingModuleConfiguration(configURLString: nil,
                                                                                  subscriptionID: "overriden.id",
                                                                                  isTooltipFeatureEnabled: true))
                        expect(configurationRepository.getSubscriptionID()).toEventually(equal("overriden.id"))
                    }
                }

                context("and tooltip feature is enabled") {

                    it("will start ViewListener when completion was called with shouldDeinit = false") {
                        RInAppMessaging.deinitializeModule()
                        expect(ViewListener.currentInstance.isListening).toEventually(beFalse())
                        reinitializeSDK(config: InAppMessagingModuleConfiguration(configURLString: nil,
                                                                                  subscriptionID: nil,
                                                                                  isTooltipFeatureEnabled: true))
                        expect(ViewListener.currentInstance.isListening).to(beTrue())
                    }

                    it("will stop ViewListener when completion was called with shouldDeinit = true") {
                        RInAppMessaging.deinitializeModule()
                        reinitializeSDK(waitForInit: false,
                                        config: InAppMessagingModuleConfiguration(configURLString: nil,
                                                                                  subscriptionID: nil,
                                                                                  isTooltipFeatureEnabled: true)) {
                            configurationManager.rolloutPercentage = 0 // triggers deinit
                        }
                        expect(ViewListener.currentInstance.isListening).toAfterTimeout(beFalse())
                    }
                }

                context("and tooltip feature is disabled") {

                    it("will not start ViewListener") {
                        RInAppMessaging.deinitializeModule()
                        expect(ViewListener.currentInstance.isListening).toEventually(beFalse())
                        reinitializeSDK(config: InAppMessagingModuleConfiguration(configURLString: nil,
                                                                                  subscriptionID: nil,
                                                                                  isTooltipFeatureEnabled: false))
                        expect(ViewListener.currentInstance.isListening).toAfterTimeout(beFalse())
                    }
                }

                context("when tryGettingValidConfigURL() is invoked") {

                    context("and a valid configURL is provided") {
                        let config = InAppMessagingModuleConfiguration(configURLString: "http://config.url",
                                                                       subscriptionID: nil,
                                                                       isTooltipFeatureEnabled: true)

                        it("will not report an error") {
                            _ = RInAppMessaging.tryGettingValidConfigURL(config)
                            expect(errorReceiver.returnedError).to(beNil())
                        }

                        it("will not throw an assertion") {
                            expect(RInAppMessaging.tryGettingValidConfigURL(config)).toNot(throwAssertion())
                        }

                        it("will return a value containing the valid url") {
                            let validURL = RInAppMessaging.tryGettingValidConfigURL(config)
                            expect(validURL).to(equal(URL(string: "http://config.url")!))
                        }
                    }

                    context("and an empty configURL is provided") {
                        let config = InAppMessagingModuleConfiguration(configURLString: "",
                                                                       subscriptionID: nil,
                                                                       isTooltipFeatureEnabled: true)

                        it("will report an error") {
                            // capturing assertion to allow further testing
                            expect(RInAppMessaging.tryGettingValidConfigURL(config)).to(throwAssertion())
                            expect(errorReceiver.returnedError).toNot(beNil())
                        }

                        it("will throw an assertion") {
                            expect(RInAppMessaging.tryGettingValidConfigURL(config)).to(throwAssertion())
                        }
                    }

                    context("and nil configURL is provided") {
                        let config = InAppMessagingModuleConfiguration(configURLString: nil,
                                                                       subscriptionID: nil,
                                                                       isTooltipFeatureEnabled: true)

                        it("will report an error") {
                            // capturing assertion to allow further testing
                            expect(RInAppMessaging.tryGettingValidConfigURL(config)).to(throwAssertion())
                            expect(errorReceiver.returnedError).toNot(beNil())
                        }

                        it("will throw an assertion") {
                            expect(RInAppMessaging.tryGettingValidConfigURL(config)).to(throwAssertion())
                        }
                    }
                }
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

                    expect(UIApplication.shared.getKeyWindow()?.findIAMView()).toEventuallyNot(beNil())
                    RInAppMessaging.closeMessage()
                    expect(UIApplication.shared.getKeyWindow()?.findIAMView()).toEventually(beNil())
                }

                it("will not decrement impressionsLeft in closed campaign") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(UIApplication.shared.getKeyWindow()?.findIAMView()).toEventuallyNot(beNil())
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

                    expect(UIApplication.shared.getKeyWindow()?.findIAMView()).toEventuallyNot(beNil())
                    UIApplication.shared.getKeyWindow()?.findIAMView()?.dismiss()
                    expect(contextVerifier.onVerifyContextCallCount).toEventually(equal(2))
                }

                it("will not show a message if the method returned false") {
                    contextVerifier.shouldShowCampaign = false
                    generateAndDisplayLoginCampaigns(count: 2, addContexts: true)

                    expect(UIApplication.shared.getKeyWindow()?.findIAMView()).toAfterTimeout(beNil())
                    expect(contextVerifier.onVerifyContextCallCount).to(equal(2))
                }

                it("will show a tooltip if the method returned true") {
                    contextVerifier.shouldShowCampaign = true
                    generateAndDisplayLoginTooltip(uiElementIdentifier: "view-id", addContexts: true)

                    expect(UIApplication.shared.getKeyWindow()?.findTooltipView()).toEventuallyNot(beNil())
                    expect(contextVerifier.onVerifyContextCallCount).to(beGreaterThan(0))
                    // multiple onVerifyContext calls are possible due to target view tracking logic updates
                }

                it("will not show a tooltip if the method returned false") {
                    contextVerifier.shouldShowCampaign = false
                    generateAndDisplayLoginTooltip(uiElementIdentifier: "view-id", addContexts: true)

                    expect(UIApplication.shared.getKeyWindow()?.findTooltipView()).toAfterTimeout(beNil())
                    expect(contextVerifier.onVerifyContextCallCount).to(beGreaterThan(0))
                    // multiple onVerifyContext calls are possible due to target view tracking logic updates
                }

                it("will call the method before showing a tooltip with expected parameters") {
                    contextVerifier.shouldShowCampaign = true
                    tooltipTargetView.accessibilityIdentifier = TooltipViewIdentifierMock
                    messageMixerService.mockedResponse = PingResponse(
                        nextPingMilliseconds: Int.max,
                        currentPingMilliseconds: 0,
                        data: [
                            TestHelpers.generateTooltip(id: "1",
                                                        title: "[Tooltip][ctx1][ctx2] title",
                                                        targetViewID: tooltipTargetView.accessibilityIdentifier,
                                                        triggers: [Trigger.loginEventTrigger])
                        ])
                    UIApplication.shared.getKeyWindow()?.addSubview(tooltipTargetView)
                    campaignsListManager.refreshList()
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(contextVerifier.onVerifyContextCallParameters?.title)
                        .toEventually(equal("[Tooltip][ctx1][ctx2] title"), timeout: .seconds(2))
                    expect(contextVerifier.onVerifyContextCallParameters?.contexts).to(contain(["Tooltip", "ctx1", "ctx2"]))
                }

                it("will call the method before showing a message with expected parameters") {
                    contextVerifier.shouldShowCampaign = true
                    messageMixerService.mockedResponse = PingResponse(
                        nextPingMilliseconds: Int.max,
                        currentPingMilliseconds: 0,
                        data: [
                            TestHelpers.generateCampaign(id: "1",
                                                         title: "[ctx1][ctx2] title",
                                                         triggers: [Trigger.loginEventTrigger])
                        ])
                    campaignsListManager.refreshList()
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(contextVerifier.onVerifyContextCallParameters?.title).toEventually(equal("[ctx1][ctx2] title"), timeout: .seconds(2))
                    expect(contextVerifier.onVerifyContextCallParameters?.contexts).to(contain(["ctx1", "ctx2"]))
                }
            }

            context("caching") {

                it("will show a message if impressionsLeft was greater than 0 in the last session") {
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(UIApplication.shared.getKeyWindow()?.findIAMView()).toEventuallyNot(beNil())
                    UIApplication.shared.getKeyWindow()?.findIAMView()?.dismiss()
                    waitForCache()

                    RInAppMessaging.deinitializeModule()
                    reinitializeSDK()
                    expect(campaignRepository.list).to(haveCount(1))
                    expect(campaignRepository.list.first?.impressionsLeft).to(equal(1))
                    generateAndDisplayLoginCampaigns(count: 1, addContexts: false)

                    expect(UIApplication.shared.getKeyWindow()?.findIAMView()).toEventuallyNot(beNil())
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

                    expect(UIApplication.shared.getKeyWindow()?.findIAMView()).toEventuallyNot(beNil())
                    UIApplication.shared.getKeyWindow()?.findIAMView()?.dismiss()
                    waitForCache()

                    RInAppMessaging.deinitializeModule()
                    reinitializeSDK()
                    messageMixerService.mockedResponse = mockedResponse
                    campaignsListManager.refreshList()
                    expect(campaignRepository.list.first?.impressionsLeft).to(equal(0))
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(UIApplication.shared.getKeyWindow()?.findIAMView()).toAfterTimeout(beNil())
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

                    expect(UIApplication.shared.getKeyWindow()?.findIAMView()).toAfterTimeout(beNil())
                }

                // As it may contain outdated information (especially after logout)
                it("will not transfer cached data (sync) from anonymous user") {
                    messageMixerService.mockedResponse = TestHelpers.MockResponse.withGeneratedCampaigns(
                        count: 1, test: false, delay: 100, maxImpressions: 2, addContexts: false,
                        triggers: [Trigger.loginEventTrigger])
                    RInAppMessaging.registerPreference(UserInfoProviderMock()) // anonymous user
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(UIApplication.shared.getKeyWindow()?.findIAMView()).toEventuallyNot(beNil())
                    UIApplication.shared.getKeyWindow()?.findIAMView()?.dismiss()
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
                        triggers: [Trigger.loginEventTrigger])

                    let emptyUser = UserInfoProviderMock()
                    emptyUser.userID = ""
                    RInAppMessaging.registerPreference(emptyUser)
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())

                    expect(UIApplication.shared.getKeyWindow()?.findIAMView()).toEventuallyNot(beNil())
                    UIApplication.shared.getKeyWindow()?.findIAMView()?.dismiss()
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

            context("pushPrimerAuthorizationOptions") {

                var pushPrimerAuthorizationOptionsDefault: UNAuthorizationOptions = []
                beforeSuite {
                    pushPrimerAuthorizationOptionsDefault = RInAppMessaging.pushPrimerAuthorizationOptions
                }

                afterEach {
                    RInAppMessaging.pushPrimerAuthorizationOptions = pushPrimerAuthorizationOptionsDefault
                }

                it("will have expected default value") {
                    expect(RInAppMessaging.pushPrimerAuthorizationOptions).to(equal([.sound, .alert, .badge]))
                }

                it("will return expected value when a new value was set") {
                    RInAppMessaging.pushPrimerAuthorizationOptions = [.carPlay]
                    expect(RInAppMessaging.pushPrimerAuthorizationOptions).to(equal([.carPlay]))
                }

                it("will not re-set the value after calling configure()") {
                    RInAppMessaging.pushPrimerAuthorizationOptions = [.criticalAlert]
                    reinitializeSDK()
                    expect(RInAppMessaging.pushPrimerAuthorizationOptions).to(equal([.criticalAlert]))
                }
            }

            context("when calling closeTooltip") {
                let tooltipTargetViewID = "view-id"

                beforeEach {
                    // ensure no tooltip is displayed
                    expect(UIApplication.shared.getKeyWindow()?.findTooltipView()).to(beNil())
                }

                context("and identifier matches") {

                    it("will remove displayed tooltip view from hierarchy") {
                        generateAndDisplayLoginTooltip(uiElementIdentifier: tooltipTargetViewID, addContexts: false)

                        expect(UIApplication.shared.getKeyWindow()?.findTooltipView()).toEventuallyNot(beNil())
                        RInAppMessaging.closeTooltip(with: tooltipTargetViewID)
                        expect(UIApplication.shared.getKeyWindow()?.findTooltipView()).toEventually(beNil())
                    }

                    it("will not decrement impressionsLeft in closed tooltip") {
                        generateAndDisplayLoginTooltip(uiElementIdentifier: tooltipTargetViewID, addContexts: false)

                        expect(UIApplication.shared.getKeyWindow()?.findTooltipView()).toEventuallyNot(beNil())
                        expect(campaignRepository.tooltipsList.first?.impressionsLeft).to(equal(2))
                        RInAppMessaging.closeTooltip(with: tooltipTargetViewID)
                        expect(campaignRepository.tooltipsList.first?.impressionsLeft).toAfterTimeout(equal(2))
                    }
                }

                context("and identifier does not match") {

                    it("will not remove displayed tooltip view from hierarchy") {
                        generateAndDisplayLoginTooltip(uiElementIdentifier: tooltipTargetViewID, addContexts: false)

                        expect(UIApplication.shared.getKeyWindow()?.findTooltipView()).toEventuallyNot(beNil())
                        RInAppMessaging.closeTooltip(with: "other-id")
                        expect(UIApplication.shared.getKeyWindow()?.findTooltipView()).toAfterTimeoutNot(beNil())
                    }
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
