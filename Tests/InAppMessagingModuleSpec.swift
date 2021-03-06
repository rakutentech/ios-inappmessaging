import Quick
import Nimble
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
            var preferenceRepository: IAMPreferenceRepository!
            var campaignsValidator: CampaignsValidatorMock!
            var eventMatcher: EventMatcherMock!
            var readyCampaignDispatcher: CampaignDispatcherMock!
            var campaignTriggerAgent: CampaignTriggerAgentType!
            var campaignRepository: CampaignRepositoryMock!
            var router: RouterMock!
            var randomizer: RandomizerMock!
            var delegate: Delegate!

            beforeEach {
                configurationManager = ConfigurationManagerMock()
                campaignsListManager = CampaignsListManagerMock()
                impressionService = ImpressionServiceMock()
                preferenceRepository = IAMPreferenceRepository()
                campaignsValidator = CampaignsValidatorMock()
                eventMatcher = EventMatcherMock()
                readyCampaignDispatcher = CampaignDispatcherMock()
                campaignTriggerAgent = CampaignTriggerAgent(eventMatcher: eventMatcher,
                                                            readyCampaignDispatcher: readyCampaignDispatcher,
                                                            campaignsValidator: campaignsValidator)
                campaignRepository = CampaignRepositoryMock()
                router = RouterMock()
                randomizer = RandomizerMock()
                delegate = Delegate()
                iamModule = InAppMessagingModule(configurationManager: configurationManager,
                                                 campaignsListManager: campaignsListManager,
                                                 impressionService: impressionService,
                                                 preferenceRepository: preferenceRepository,
                                                 eventMatcher: eventMatcher,
                                                 readyCampaignDispatcher: readyCampaignDispatcher,
                                                 campaignTriggerAgent: campaignTriggerAgent,
                                                 campaignRepository: campaignRepository,
                                                 router: router,
                                                 randomizer: randomizer)
                iamModule.delegate = delegate
            }

            it("is enabled by deafult") {
                expect(iamModule.isEnabled).to(beTrue())
            }

            it("will return true for shouldShowCampaignMessage if delegate is nil") {
                iamModule.delegate = nil
                expect(iamModule.shouldShowCampaignMessage(title: "", contexts: [])).to(beTrue())
            }

            it("will call delegate method if shouldShowCampaignMessage was called") {
                _ = iamModule.shouldShowCampaignMessage(title: "", contexts: [])
                expect(delegate.wasShouldShowCampaignCalled).to(beTrue())
            }

            context("when calling initialize") {

                it("will call fetchAndSaveConfigData in ConfigurationManager") {
                    var fetchCalled = false
                    configurationManager.fetchCalledClosure = {
                        fetchCalled = true
                    }
                    iamModule.initialize { }

                    expect(fetchCalled).to(beTrue())
                }

                it("will not call fetchAndSaveConfigData in ConfigurationManager when initilized for the second time") {
                    iamModule.initialize { }
                    var fetchCalled = false
                    configurationManager.fetchCalledClosure = {
                        fetchCalled = true
                    }
                    iamModule.initialize { }

                    expect(fetchCalled).to(beFalse())
                }

                context("and module is enabled") {
                    beforeEach {
                        configurationManager.rolloutPercentage = 100
                    }

                    it("will call refreshList in CampaignsListManager") {
                        configurationManager.rolloutPercentage = 100
                        iamModule.initialize { }

                        expect(campaignsListManager.wasRefreshListCalled).to(beTrue())
                    }

                    it("will not call deinit handler") {
                        var deinitCalled = false
                        iamModule.initialize {
                            deinitCalled = true
                        }

                        expect(deinitCalled).toAfterTimeout(beFalse())
                    }
                }

                context("and module is partially enabled") {
                    [(1, 2), (50, 51), (99, 100)].forEach { (rolloutPercentage, returnedValue) in
                        it("will not call refreshList in CampaignsListManager") {
                             configurationManager.rolloutPercentage = rolloutPercentage
                             randomizer.returnedValue = UInt(returnedValue)
                             iamModule.initialize { }

                             expect(campaignsListManager.wasRefreshListCalled).to(beFalse())
                        }
                    }

                    [(1, 1), (50, 49), (50, 50), (99, 98), (99, 99), (100, 100)].forEach { (rolloutPercentage, returnedValue) in
                        it("will call refreshList in CampaignsListManager") {
                             configurationManager.rolloutPercentage = rolloutPercentage
                             randomizer.returnedValue = UInt(returnedValue)
                             iamModule.initialize { }

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
                        iamModule.initialize { }

                        expect(campaignsListManager.wasRefreshListCalled).to(beFalse())
                    }

                    it("will call deinit handler") {
                        var deinitCalled = false
                        iamModule.initialize {
                            deinitCalled = true
                        }

                        expect(deinitCalled).to(beTrue())
                    }
                }

                context("and fetchAndSaveConfigData has not finished") {
                    let queue = DispatchQueue(label: "iamTestQueue")

                    beforeEach {
                        configurationManager.fetchCalledClosure = {
                            sleep(2)
                        }
                        queue.async {
                            iamModule.initialize { }
                        }
                    }

                    it("should wait synchronously with logEvent method") {
                        queue.async {
                            iamModule.logEvent(AppStartEvent())
                        }
                        expect(eventMatcher.loggedEvents).toAfterTimeout(beEmpty())
                        expect(eventMatcher.loggedEvents).toEventually(haveCount(1), timeout: .seconds(2))
                    }

                    it("should wait synchronously with registerPreference method") {
                        let preference = IAMPreferenceBuilder().setUserId("user").build()
                        queue.async {
                            iamModule.registerPreference(preference)
                        }
                        expect(preferenceRepository.preference).toAfterTimeout(beNil())
                        expect(preferenceRepository.preference).toEventually(equal(preference), timeout: .seconds(2))
                    }
                }

                context("and fetchAndSaveConfigData errored (waiting for retry)") {

                    beforeEach {
                        configurationManager.simulateRetryDelay = 1
                        iamModule.initialize { }
                    }

                    it("will log all buferred events when module is enabled") {
                        configurationManager.rolloutPercentage = 100
                        iamModule.logEvent(AppStartEvent())
                        iamModule.logEvent(LoginSuccessfulEvent())
                        expect(eventMatcher.loggedEvents).to(beEmpty())
                        expect(campaignsValidator.wasValidateCalled).to(beFalse())
                        expect(eventMatcher.loggedEvents).toEventually(haveCount(2), timeout: .seconds(2))
                        expect(campaignsValidator.wasValidateCalled).to(beTrue())
                    }

                    it("will not log buferred events when module is disabled") {
                        configurationManager.rolloutPercentage = 0
                        iamModule.logEvent(AppStartEvent())
                        iamModule.logEvent(LoginSuccessfulEvent())
                        expect(eventMatcher.loggedEvents).toAfterTimeout(beEmpty(), timeout: 2)
                        expect(campaignsValidator.wasValidateCalled).toAfterTimeout(beFalse(), timeout: 2)
                    }
                }

                context("when calling logEvent") {

                    context("and module is enabled") {
                        beforeEach {
                            configurationManager.rolloutPercentage = 100
                        }

                        context("and module is initialized") {
                            beforeEach {
                                iamModule.initialize { }
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
                        }

                        context("and module is not initialized") {

                            it("will not call EventMatcher") {
                                iamModule.logEvent(PurchaseSuccessfulEvent())
                                expect(eventMatcher.loggedEvents).toAfterTimeout(beEmpty())
                            }

                            it("will not validate campaigns") {
                                iamModule.logEvent(PurchaseSuccessfulEvent())
                                expect(campaignsValidator.wasValidateCalled).toAfterTimeout(beFalse())
                            }

                            it("will not call dispatchAllIfNeeded") {
                                iamModule.logEvent(PurchaseSuccessfulEvent())
                                expect(readyCampaignDispatcher.wasDispatchCalled).toAfterTimeout(beFalse())
                            }
                        }
                    }

                    context("and module is disabled") {
                        beforeEach {
                            configurationManager.rolloutPercentage = 0
                            iamModule.initialize { }
                        }

                        it("will not call EventMatcher") {
                            iamModule.logEvent(PurchaseSuccessfulEvent())
                            expect(eventMatcher.loggedEvents.isEmpty).toAfterTimeout(beTrue())
                        }

                        it("will not validate campaigns") {
                            iamModule.logEvent(PurchaseSuccessfulEvent())
                            expect(campaignsValidator.wasValidateCalled).toAfterTimeout(beFalse())
                        }

                        it("will not call dispatchAllIfNeeded") {
                            iamModule.logEvent(PurchaseSuccessfulEvent())
                            expect(readyCampaignDispatcher.wasDispatchCalled).toAfterTimeout(beFalse())
                        }
                    }
                }

                context("when calling registerPreference") {

                    let aUser = IAMPreferenceBuilder().setUserId("user").build()

                    context("and module is enabled") {
                        beforeEach {
                            configurationManager.rolloutPercentage = 100
                        }

                        context("and module is initialized") {
                            beforeEach {
                                iamModule.initialize { }
                            }

                            it("will register preference data") {
                                let preference = IAMPreferenceBuilder().setUserId("user").build()
                                iamModule.registerPreference(preference)
                                expect(preferenceRepository.preference).to(equal(preference))
                            }

                            it("will refresh list of campaigns") {
                                iamModule.registerPreference(IAMPreference())
                                expect(campaignsListManager.wasRefreshListCalled).to(beTrue())
                            }

                            it("will reload campaigns repository cache") {
                                iamModule.registerPreference(IAMPreference())
                                expect(campaignRepository.wasLoadCachedDataCalled).to(beTrue())
                            }

                            it("will reload campaigns repository cache with syncWithLastUserData set to false") {
                                iamModule.registerPreference(aUser)
                                expect(campaignRepository.wasLoadCachedDataCalled).to(beTrue())
                                expect(campaignRepository.loadCachedDataParameters).to(equal((false)))
                            }

                            it("will clear last user data when user logs out or changes to another user") {
                                [(aUser, nil), (aUser, IAMPreference()),
                                 (aUser, IAMPreferenceBuilder().setUserId("userB").build())]
                                    .forEach { prefA, prefB in
                                        iamModule.registerPreference(prefA)
                                        campaignRepository.resetFlags()
                                        iamModule.registerPreference(prefB)
                                        expect(campaignRepository.wasClearLastUserDataCalled).to(beTrue())
                                    }
                            }

                            it("will not clear last user data when user did not log out or change to another user") {
                                [(nil, aUser), (IAMPreference(), aUser),
                                 (nil, nil), (nil, IAMPreference()),
                                 (IAMPreference(), nil), (IAMPreference(), IAMPreference())]
                                    .forEach { prefA, prefB in
                                        iamModule.registerPreference(prefA)
                                        campaignRepository.resetFlags()
                                        iamModule.registerPreference(prefB)
                                        expect(campaignRepository.wasClearLastUserDataCalled).to(beFalse())
                                    }
                            }

                            it("will clear event list when user logs out or changes to another user") {
                                [(aUser, nil), (aUser, IAMPreference()),
                                 (aUser, IAMPreferenceBuilder().setUserId("userB").build())]
                                    .forEach { prefA, prefB in
                                        iamModule.registerPreference(prefA)
                                        eventMatcher.wasClearNonPersistentEventsCalled = false // reset
                                        iamModule.registerPreference(prefB)
                                        expect(eventMatcher.wasClearNonPersistentEventsCalled).to(beTrue())
                                    }
                            }

                            it("will not clear event list when user did not log out or change to another user") {
                                [(nil, aUser), (IAMPreference(), aUser),
                                 (nil, nil), (nil, IAMPreference()),
                                 (IAMPreference(), nil), (IAMPreference(), IAMPreference())]
                                    .forEach { prefA, prefB in
                                        iamModule.registerPreference(prefA)
                                        eventMatcher.wasClearNonPersistentEventsCalled = false // reset
                                        iamModule.registerPreference(prefB)
                                        expect(eventMatcher.wasClearNonPersistentEventsCalled).to(beFalse())
                                    }
                            }
                        }

                        context("and module is not initialized") {

                            it("will register preference data") {
                                let preference = IAMPreferenceBuilder().setUserId("user").build()
                                iamModule.registerPreference(preference)
                                expect(preferenceRepository.preference).to(equal(preference))
                            }

                            it("will not refresh list of campaigns") {
                                iamModule.registerPreference(IAMPreference())
                                expect(campaignsListManager.wasRefreshListCalled).toAfterTimeout(beFalse())
                            }

                            it("will not reload campaigns repository cache") {
                                iamModule.registerPreference(IAMPreference())
                                expect(campaignRepository.wasLoadCachedDataCalled).to(beFalse())
                            }

                            it("will not reset dispatch queue even if new preference has different ids") {
                                iamModule.registerPreference(IAMPreferenceBuilder().setUserId("user").build())
                                readyCampaignDispatcher.wasResetQueueCalled = false
                                iamModule.registerPreference(IAMPreferenceBuilder().setUserId("user2").build())
                                expect(readyCampaignDispatcher.wasResetQueueCalled).to(beFalse())
                            }
                        }
                    }

                    context("and module is disabled") {
                        beforeEach {
                            configurationManager.rolloutPercentage = 0
                            iamModule.initialize { }
                        }

                        it("will not register preference data") {
                            let preference = IAMPreferenceBuilder().setUserId("user").build()
                            iamModule.registerPreference(preference)
                            expect(preferenceRepository.preference).toAfterTimeout(beNil())
                        }

                        it("will not refresh list of campaigns") {
                            iamModule.registerPreference(IAMPreference())
                            expect(campaignsListManager.wasRefreshListCalled).toAfterTimeout(beFalse())
                        }

                        it("will not reload campaigns repository cache") {
                            iamModule.registerPreference(IAMPreference())
                            expect(campaignRepository.wasLoadCachedDataCalled).to(beFalse())
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

                context("as CampaignDispatcherDelegate") {

                    it("will refresh list of campaigns when performPing was called") {
                        iamModule.performPing()
                        expect(campaignsListManager.wasRefreshListCalled).to(beTrue())
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
        }
    }
}

private class Delegate: RInAppMessagingDelegate {
    var wasShouldShowCampaignCalled = false

    func inAppMessagingShouldShowCampaignWithContexts(contexts: [String], campaignTitle: String) -> Bool {
        wasShouldShowCampaignCalled = true
        return true
    }
}
