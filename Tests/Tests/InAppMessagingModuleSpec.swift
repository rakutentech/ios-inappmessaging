import Foundation
import Quick
import Nimble

#if canImport(RSDKUtilsNimble)
import RSDKUtilsNimble // SPM version
#else
import RSDKUtils
#endif

@testable import RInAppMessaging

// swiftlint:disable:next type_body_length
class InAppMessagingModuleSpec: QuickSpec {

    // swiftlint:disable:next function_body_length
    override func spec() {

        describe("InAppMessagingModule") {

            var iamModule: InAppMessagingModule!
            var configurationManager: ConfigurationManagerMock!
            var campaignsListManager: CampaignsListManagerMock!
            var impressionService: ImpressionServiceMock!
            var accountRepository: AccountRepositorySpy!
            var campaignsValidator: CampaignsValidatorMock!
            var eventMatcher: EventMatcherMock!
            var readyCampaignDispatcher: CampaignDispatcherMock!
            var campaignTriggerAgent: CampaignTriggerAgentType!
            var campaignRepository: CampaignRepositoryMock!
            var router: RouterMock!
            var randomizer: RandomizerMock!

            beforeEach {
                configurationManager = ConfigurationManagerMock()
                campaignsListManager = CampaignsListManagerMock()
                impressionService = ImpressionServiceMock()
                accountRepository = AccountRepositorySpy()
                campaignsValidator = CampaignsValidatorMock()
                eventMatcher = EventMatcherMock()
                readyCampaignDispatcher = CampaignDispatcherMock()
                campaignTriggerAgent = CampaignTriggerAgent(eventMatcher: eventMatcher,
                                                            readyCampaignDispatcher: readyCampaignDispatcher,
                                                            tooltipDispatcher: TooltipDispatcherMock(),
                                                            campaignsValidator: campaignsValidator)
                campaignRepository = CampaignRepositoryMock()
                router = RouterMock()
                randomizer = RandomizerMock()
                iamModule = InAppMessagingModule(configurationManager: configurationManager,
                                                 campaignsListManager: campaignsListManager,
                                                 impressionService: impressionService,
                                                 accountRepository: accountRepository,
                                                 eventMatcher: eventMatcher,
                                                 readyCampaignDispatcher: readyCampaignDispatcher,
                                                 campaignTriggerAgent: campaignTriggerAgent,
                                                 campaignRepository: campaignRepository,
                                                 router: router,
                                                 randomizer: randomizer,
                                                 displayPermissionService: DisplayPermissionServiceMock(),
                                                 tooltipDispatcher: TooltipDispatcherMock())
            }

            context("when calling initialize") {

                it("will call fetchAndSaveConfigData in ConfigurationManager") {
                    var fetchCalled = false
                    configurationManager.fetchCalledClosure = {
                        fetchCalled = true
                    }
                    iamModule.initialize { _ in }

                    expect(fetchCalled).to(beTrue())
                }

                it("will not call fetchAndSaveConfigData in ConfigurationManager when initilized for the second time") {
                    iamModule.initialize { _ in }
                    var fetchCalled = false
                    configurationManager.fetchCalledClosure = {
                        fetchCalled = true
                    }
                    iamModule.initialize { _ in }

                    expect(fetchCalled).to(beFalse())
                }

                context("and module is enabled") {
                    beforeEach {
                        configurationManager.rolloutPercentage = 100
                    }

                    it("will call refreshList in CampaignsListManager") {
                        configurationManager.rolloutPercentage = 100
                        iamModule.initialize { _ in }

                        expect(campaignsListManager.wasRefreshListCalled).to(beTrue())
                    }

                    it("will not call deinit handler") {
                        waitUntil { done in
                            iamModule.initialize { shouldDeinit in
                                expect(shouldDeinit).to(beFalse())
                                done()
                            }
                        }
                    }
                }

                context("and module is partially enabled") {
                    [(1, 2), (50, 51), (99, 100)].forEach { (rolloutPercentage, returnedValue) in
                        it("will not call refreshList in CampaignsListManager") {
                             configurationManager.rolloutPercentage = rolloutPercentage
                             randomizer.returnedValue = UInt(returnedValue)
                             iamModule.initialize { _ in }

                             expect(campaignsListManager.wasRefreshListCalled).to(beFalse())
                        }
                    }

                    [(1, 1), (50, 49), (50, 50), (99, 98), (99, 99), (100, 100)].forEach { (rolloutPercentage, returnedValue) in
                        it("will call refreshList in CampaignsListManager") {
                             configurationManager.rolloutPercentage = rolloutPercentage
                             randomizer.returnedValue = UInt(returnedValue)
                             iamModule.initialize { _ in }

                             expect(campaignsListManager.wasRefreshListCalled).to(beTrue())
                        }
                    }

                    afterEach {
                        randomizer.returnedValue = 0
                    }
                }

                context("and module is disabled") {
                    beforeEach {
                        configurationManager.rolloutPercentage = 0
                    }

                    it("will not call refreshList in CampaignsListManager") {
                        iamModule.initialize { _ in }

                        expect(campaignsListManager.wasRefreshListCalled).to(beFalse())
                    }

                    it("will call deinit handler") {
                        waitUntil { done in
                            iamModule.initialize { shouldDeinit in
                                expect(shouldDeinit).to(beTrue())
                                done()
                            }
                        }
                    }
                }

                context("and fetchAndSaveConfigData has not finished") {
                    let queue = DispatchQueue(label: "iamTestQueue")
                    let configSemaphore = DispatchGroup()

                    beforeEach {
                        configurationManager.fetchCalledClosure = {
                            configSemaphore.wait()
                        }
                        configSemaphore.enter()
                        queue.async {
                            iamModule.initialize { _ in }
                        }
                    }

                    it("should wait synchronously with logEvent method") {
                        queue.async {
                            iamModule.logEvent(AppStartEvent())
                        }
                        expect(eventMatcher.loggedEvents).toAfterTimeout(beEmpty())
                        configSemaphore.leave()
                        expect(eventMatcher.loggedEvents).toEventually(haveCount(1))
                    }

                    it("should wait synchronously with registerPreference method") {
                        let preference = UserInfoProviderMock()
                        queue.async {
                            iamModule.registerPreference(preference)
                        }
                        expect(accountRepository.userInfoProvider).toAfterTimeout(beNil())
                        configSemaphore.leave()
                        expect(accountRepository.userInfoProvider).toEventually(beIdenticalTo(preference))
                    }
                }

                context("and fetchAndSaveConfigData errored (waiting for retry)") {

                    var resume: (() -> Void)!

                    beforeEach {
                        resume = configurationManager.prepareRetryDelayAndWaitForSignal()
                        iamModule.initialize { _ in }
                    }

                    it("will not log any events when module is disabled") {
                        configurationManager.rolloutPercentage = 0
                        iamModule.logEvent(AppStartEvent())
                        iamModule.logEvent(LoginSuccessfulEvent())
                        resume()
                        expect(eventMatcher.loggedEvents).to(beEmpty())
                        expect(campaignsValidator.wasValidateCalled).to(beFalse())
                    }
                }

                context("when calling logEvent") {

                    context("and module is initialized") {
                        beforeEach {
                            iamModule.initialize { _ in }
                        }

                        it("will call EventMatcher") {
                            iamModule.logEvent(PurchaseSuccessfulEvent())
                            expect(eventMatcher.loggedEvents).toEventually(haveCount(1))
                        }

                        it("will validate campaigns") {
                            iamModule.logEvent(PurchaseSuccessfulEvent())
                            expect(campaignsValidator.wasValidateCalled).to(beTrue())
                        }

                        it("will trigger campaigns that should be triggered") {
                            let campaigns = [TestHelpers.generateCampaign(id: "1"),
                                             TestHelpers.generateCampaign(id: "2")]
                            campaignsValidator.campaignsToTrigger = campaigns
                            iamModule.logEvent(PurchaseSuccessfulEvent())
                            expect(readyCampaignDispatcher.addedCampaignIDs).to(equal(campaigns.map({ $0.id })))
                        }

                        it("will call dispatchAllIfNeeded") {
                            iamModule.logEvent(PurchaseSuccessfulEvent())
                            expect(readyCampaignDispatcher.wasDispatchCalled).to(beTrue())
                        }

                        it("will call checkUserChanges()") {
                            iamModule.logEvent(PurchaseSuccessfulEvent())
                            // checkUserChanges() always calls AccountRepository.updateUserInfo().
                            // This is a workaround for checking if the method was called on a real InAppMessagingModule's instance.
                            // Checking this method call instead of testing a cause will significantly reduce the amount
                            // of test cases in this spec.
                            expect(accountRepository.wasUpdateUserInfoCalled).to(beTrue())
                        }
                    }

                    context("and module is not initialized") {

                        it("will not call EventMatcher") {
                            iamModule.logEvent(PurchaseSuccessfulEvent())
                            expect(eventMatcher.loggedEvents).to(beEmpty())
                        }

                        it("will not validate campaigns") {
                            iamModule.logEvent(PurchaseSuccessfulEvent())
                            expect(campaignsValidator.wasValidateCalled).to(beFalse())
                        }

                        it("will not call dispatchAllIfNeeded") {
                            iamModule.logEvent(PurchaseSuccessfulEvent())
                            expect(readyCampaignDispatcher.wasDispatchCalled).to(beFalse())
                        }

                        it("will not call checkUserChanges()") {
                            iamModule.logEvent(PurchaseSuccessfulEvent())
                            expect(accountRepository.wasUpdateUserInfoCalled).to(beFalse())
                        }
                    }
                }

                context("when calling registerPreference") {

                    let aUser: UserInfoProvider = {
                        let user = UserInfoProviderMock()
                        user.userID = "user"
                        return user
                    }()

                    context("and module is initialized") {
                        beforeEach {
                            iamModule.initialize { _ in }
                        }

                        it("will register preference data") {
                            iamModule.registerPreference(aUser)
                            expect(accountRepository.userInfoProvider).to(beIdenticalTo(aUser))
                        }

                        it("will call checkUserChanges()") {
                            iamModule.registerPreference(aUser)
                            // checkUserChanges() always calls AccountRepository.updateUserInfo().
                            // This is a workaround for checking if the method was called on a real InAppMessagingModule's instance.
                            // Checking this method call instead of testing a cause will significantly reduce the amount
                            // of test cases in this spec.
                            expect(accountRepository.wasUpdateUserInfoCalled).to(beTrue())
                        }
                    }

                    context("and module is not initialized") {

                        it("will register preference data") {
                            iamModule.registerPreference(aUser)
                            expect(accountRepository.userInfoProvider).to(beIdenticalTo(aUser))
                        }

                        it("will call updateUserInfo() to update cached user data") {
                            iamModule.registerPreference(aUser)
                            expect(accountRepository.wasUpdateUserInfoCalled).to(beTrue())
                        }
                    }
                }

                context("when calling closeMessage") {

                    it("will discard displayed campaign even if module is not initialized") {
                        iamModule.closeMessage(clearQueuedCampaigns: false)
                        expect(router.wasDiscardCampaignCalled).to(beTrue())
                    }

                    it("will reset queued campaigns list if `clearQueuedCampaigns` is true") {
                        iamModule.closeMessage(clearQueuedCampaigns: true)
                        expect(readyCampaignDispatcher.wasResetQueueCalled).to(beTrue())
                    }

                    it("will not reset queued campaigns list if `clearQueuedCampaigns` is false") {
                        let campaign = TestHelpers.generateCampaign(id: "test")
                        router.lastDisplayedCampaign = campaign

                        iamModule.closeMessage(clearQueuedCampaigns: false)
                        expect(readyCampaignDispatcher.wasResetQueueCalled).to(beFalse())
                    }
                }

                context("when calling checkUserChanges()") {

                    it("will call updateUserInfo()") {
                        iamModule.checkUserChanges()
                        expect(accountRepository.wasUpdateUserInfoCalled).to(beTrue())
                    }

                    it("will not reset dispatch queue even if new preference has different ids") {
                        let aUser = UserInfoProviderMock()
                        aUser.userID = "userA"
                        accountRepository.setPreference(aUser)
                        accountRepository.updateUserInfo() // initial call
                        aUser.userID = "userB"
                        readyCampaignDispatcher.wasResetQueueCalled = false
                        iamModule.checkUserChanges()
                        expect(readyCampaignDispatcher.wasResetQueueCalled).to(beFalse())
                    }

                    context("when user was updated") {
                        beforeEach {
                            let aUser = UserInfoProviderMock()
                            aUser.userID = "userA"
                            accountRepository.setPreference(aUser)
                            accountRepository.updateUserInfo() // initial call
                            aUser.userID = "userB"
                        }

                        it("will refresh list of campaigns") {
                            iamModule.checkUserChanges()
                            expect(campaignsListManager.wasRefreshListCalled).to(beTrue())
                        }

                        it("will reload campaigns repository cache") {
                            campaignRepository.resetFlags()
                            iamModule.checkUserChanges()
                            expect(campaignRepository.wasLoadCachedDataCalled).to(beTrue())
                        }

                        it("will clear event list") {
                            eventMatcher.wasClearNonPersistentEventsCalled = false // reset
                            iamModule.checkUserChanges()
                            expect(eventMatcher.wasClearNonPersistentEventsCalled).to(beTrue())
                        }
                    }

                    context("when user logs out") {
                        beforeEach {
                            let aUser = UserInfoProviderMock()
                            aUser.userID = "userA"
                            accountRepository.setPreference(aUser)
                            accountRepository.updateUserInfo() // initial call
                            aUser.userID = nil
                        }

                        it("will refresh list of campaigns") {
                            iamModule.checkUserChanges()
                            expect(campaignsListManager.wasRefreshListCalled).to(beTrue())
                        }

                        it("will reload campaigns repository cache") {
                            campaignRepository.resetFlags()
                            iamModule.checkUserChanges()
                            expect(campaignRepository.wasLoadCachedDataCalled).to(beTrue())
                        }

                        it("will clear event list") {
                            eventMatcher.wasClearNonPersistentEventsCalled = false // reset
                            iamModule.checkUserChanges()
                            expect(eventMatcher.wasClearNonPersistentEventsCalled).to(beTrue())
                        }
                    }

                    context("when user is registered for the first time") {
                        beforeEach {
                            let aUser = UserInfoProviderMock()
                            aUser.userID = "userA"
                            accountRepository.setPreference(aUser)
                        }

                        it("will refresh list of campaigns") {
                            iamModule.checkUserChanges()
                            expect(campaignsListManager.wasRefreshListCalled).to(beTrue())
                        }

                        it("will reload campaigns repository cache") {
                            campaignRepository.resetFlags()
                            iamModule.checkUserChanges()
                            expect(campaignRepository.wasLoadCachedDataCalled).to(beTrue())
                        }

                        it("will not clear event list") {
                            eventMatcher.wasClearNonPersistentEventsCalled = false // reset
                            iamModule.checkUserChanges()
                            expect(eventMatcher.wasClearNonPersistentEventsCalled).to(beFalse())
                        }
                    }

                    context("when user did not change") {
                        beforeEach {
                            let aUser = UserInfoProviderMock()
                            aUser.userID = "userA"
                            accountRepository.setPreference(aUser)
                            accountRepository.updateUserInfo() // initial call
                        }

                        it("will not refresh list of campaigns") {
                            iamModule.checkUserChanges()
                            expect(campaignsListManager.wasRefreshListCalled).to(beFalse())
                        }

                        it("will not reload campaigns repository cache") {
                            campaignRepository.resetFlags()
                            iamModule.checkUserChanges()
                            expect(campaignRepository.wasLoadCachedDataCalled).to(beFalse())
                        }

                        it("will not clear event list") {
                            eventMatcher.wasClearNonPersistentEventsCalled = false // reset
                            iamModule.checkUserChanges()
                            expect(eventMatcher.wasClearNonPersistentEventsCalled).to(beFalse())
                        }
                    }

                    context("when only access token was updated") {
                        beforeEach {
                            let aUser = UserInfoProviderMock()
                            aUser.userID = "userA"
                            accountRepository.setPreference(aUser)
                            accountRepository.updateUserInfo() // initial call
                            aUser.accessToken = "token"
                        }

                        it("will not refresh list of campaigns") {
                            iamModule.checkUserChanges()
                            expect(campaignsListManager.wasRefreshListCalled).to(beFalse())
                        }

                        it("will not reload campaigns repository cache") {
                            campaignRepository.resetFlags()
                            iamModule.checkUserChanges()
                            expect(campaignRepository.wasLoadCachedDataCalled).to(beFalse())
                        }

                        it("will not clear event list") {
                            eventMatcher.wasClearNonPersistentEventsCalled = false // reset
                            iamModule.checkUserChanges()
                            expect(eventMatcher.wasClearNonPersistentEventsCalled).to(beFalse())
                        }
                    }
                }

                context("as CampaignDispatcherDelegate") {

                    it("will return true for shouldShowCampaignMessage if onVerifyContext is nil") {
                        iamModule.onVerifyContext = nil
                        expect(iamModule.shouldShowCampaignMessage(title: "", contexts: [])).to(beTrue())
                    }

                    it("will call onVerifyContext if shouldShowCampaignMessage was called") {
                        var onVerifyContextCalled = false
                        iamModule.onVerifyContext = { _, _ in
                            onVerifyContextCalled = true
                            return true
                        }
                        _ = iamModule.shouldShowCampaignMessage(title: "", contexts: [])

                        expect(onVerifyContextCalled).to(beTrue())
                    }

                    it("will refresh list of campaigns when performPing was called") {
                        iamModule.performPing()
                        expect(campaignsListManager.wasRefreshListCalled).to(beTrue())
                    }
                }

                context("as TooltipDispatcherDelegate") {

                    it("will return true for shouldShowTooltip if onVerifyContext is nil") {
                        iamModule.onVerifyContext = nil
                        expect(iamModule.shouldShowTooltip(title: "", contexts: [])).to(beTrue())
                    }

                    it("will call onVerifyContext if shouldShowTooltip was called") {
                        var onVerifyContextCalled = false
                        iamModule.onVerifyContext = { _, _ in
                            onVerifyContextCalled = true
                            return true
                        }
                        _ = iamModule.shouldShowTooltip(title: "", contexts: [])

                        expect(onVerifyContextCalled).to(beTrue())
                    }
                }

                context("as ErrorDelegate") {

                    var forwardedError: NSError?

                    beforeEach {
                        forwardedError = nil
                        iamModule.aggregatedErrorHandler = { error in
                            forwardedError = error
                        }
                    }

                    context("when configurationManager returned an error") {

                        it("will call aggregatedErrorHandler forwarding error object") {
                            configurationManager.reportError(description: "some error", data: Data())
                            expect(forwardedError).toNot(beNil())
                            expect(forwardedError?.localizedDescription).to(equal("InAppMessaging: some error"))
                            expect(forwardedError?.userInfo["data"] as? Data).to(equal(Data()))
                        }
                    }

                    context("when campaignsListManager returned an error") {

                        it("will call aggregatedErrorHandler forwarding error object") {
                            campaignsListManager.reportError(description: "some error", data: Data())
                            expect(forwardedError).toNot(beNil())
                            expect(forwardedError?.localizedDescription).to(equal("InAppMessaging: some error"))
                            expect(forwardedError?.userInfo["data"] as? Data).to(equal(Data()))
                        }
                    }

                    context("when impressionService returned an error") {

                        it("will call aggregatedErrorHandler forwarding error object") {
                            impressionService.reportError(description: "some error", data: Data())
                            expect(forwardedError).toNot(beNil())
                            expect(forwardedError?.localizedDescription).to(equal("InAppMessaging: some error"))
                            expect(forwardedError?.userInfo["data"] as? Data).to(equal(Data()))
                        }
                    }
                }
            }

            context("when calling closeTooltip()") {
                it("will tell router to discard displayed tooltip with matching identifier") {
                    let tooltipID = "tooltip-target-id"
                    iamModule.closeTooltip(with: tooltipID)
                    expect(router.lastIdentifierOfDiscardedTooltip).to(equal(tooltipID))
                }
            }
        }
    }
}
