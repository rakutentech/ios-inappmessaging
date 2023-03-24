import Quick
import Nimble

#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsNimble
#endif

@testable import RInAppMessaging

class CampaignRepositorySpec: QuickSpec {

    override func spec() {
        describe("CampaignRepository") {

            var campaignRepository: CampaignRepository!
            var userDataCache: UserDataCacheMock!
            var accountRepository: AccountRepositoryType!
            var firstPersistedCampaign: Campaign? {
                campaignRepository.list.first
            }
            var userCache: UserDataCacheContainer? {
                userDataCache.cachedData[accountRepository.getUserIdentifiers()]
            }
            let userInfoProvider = UserInfoProviderMock()
            let campaign = TestHelpers.generateCampaign(id: "campaign-id",
                                                        maxImpressions: 3)
            let testCampaign = TestHelpers.generateCampaign(id: "test-campaign-id",
                                                            maxImpressions: 3,
                                                            test: true)
            let tooltip = TestHelpers.generateTooltip(id: "tooltip-id",
                                                      maxImpressions: 3)
            let testTooltip = TestHelpers.generateTooltip(id: "tooltip-id-test",
                                                          isTest: true,
                                                          maxImpressions: 3)

            func insertRandomCampaigns() {
                let campaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 1).data
                syncRepository(with: campaigns)
            }

            func syncRepository(with campaigns: [Campaign], ignoreTooltips: Bool = false) {
                campaignRepository.syncWith(list: campaigns, timestampMilliseconds: 0, ignoreTooltips: ignoreTooltips)
            }

            beforeEach {
                userInfoProvider.clear()
                userDataCache = UserDataCacheMock()
                accountRepository = AccountRepository(userDataCache: userDataCache)
                accountRepository.setPreference(userInfoProvider)
                campaignRepository = CampaignRepository(userDataCache: userDataCache,
                                                        accountRepository: accountRepository)
            }

            it("will load current user's cached data during initialization") {
                userDataCache.userDataMock = UserDataCacheContainer(campaignData: [campaign])
                let campaignRepository = CampaignRepository(userDataCache: userDataCache,
                                                            accountRepository: accountRepository)
                expect(campaignRepository.list).to(equal([campaign]))
            }

            context("when syncing") {
                context("campaign") {

                    it("will add new campaigns to the list") {
                        insertRandomCampaigns()
                        let newCampaigns = [campaign, testCampaign]
                        syncRepository(with: newCampaigns)
                        expect(campaignRepository.list).to(contain(newCampaigns))
                    }

                    it("will remove not existing campaigns") {
                        var campaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 1).data
                        syncRepository(with: campaigns)
                        expect(campaignRepository.list).to(haveCount(2))

                        campaigns.removeLast()
                        syncRepository(with: campaigns)
                        expect(campaignRepository.list).to(haveCount(1))
                    }

                    it("will persist impressionsLeft value") {
                        syncRepository(with: [campaign])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))

                        syncRepository(with: [campaign])
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))
                    }

                    it("will persist impressionsLeft value for test campaigns") {
                        syncRepository(with: [testCampaign])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))

                        syncRepository(with: [testCampaign])
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))
                    }

                    it("will persist isOptedOut value") {
                        syncRepository(with: [campaign])
                        expect(firstPersistedCampaign?.isOptedOut).to(beFalse())

                        campaignRepository.optOutCampaign(campaign)
                        syncRepository(with: [campaign])
                        expect(firstPersistedCampaign?.isOptedOut).to(beTrue())
                    }

                    it("will not override impressionsLeft value even if maxImpressions number is smaller") {
                        syncRepository(with: [campaign])
                        campaignRepository.incrementImpressionsLeftInCampaign(id: campaign.id)
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))

                        syncRepository(with: [campaign])
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                    }

                    it("will modify impressionsLeft if maxImpressions value is different (campaign modification)") {
                        syncRepository(with: [campaign])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
                        campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(1))

                        let updatedCampaign = TestHelpers.generateCampaign(id: campaign.id,
                                                                           maxImpressions: 6,
                                                                           test: false)
                        syncRepository(with: [updatedCampaign])
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                    }

                    it("will save updated list to the cache (anonymous user)") {
                        syncRepository(with: [campaign])
                        expect(userDataCache.cachedCampaignData).to(equal([campaign]))
                    }

                    it("will save updated list to the cache (logged-in user)") {
                        userInfoProvider.userID = "user"
                        syncRepository(with: [campaign])
                        expect(userCache?.campaignData).to(equal([campaign]))
                    }

                    it("will save test campaigns to the cache") {
                        userInfoProvider.userID = "user"
                        syncRepository(with: [testCampaign])
                        expect(userCache?.campaignData).to(equal([testCampaign]))
                    }
                }

                context("tooltip") {

                    it("will add new tooltips to the list if `ignoreTooltips` is false") {
                        insertRandomCampaigns()
                        let newTooltips = [tooltip, testTooltip]
                        syncRepository(with: newTooltips, ignoreTooltips: false)
                        expect(campaignRepository.list).to(contain(newTooltips))
                        expect(campaignRepository.tooltipsList).to(equal(newTooltips))
                    }

                    it("will NOT add new tooltips to the list if `ignoreTooltips` is true") {
                        insertRandomCampaigns()
                        let newTooltips = [tooltip, testTooltip]
                        syncRepository(with: newTooltips, ignoreTooltips: true)
                        expect(campaignRepository.list).toNot(containElementSatisfying({ $0.isTooltip }))
                        expect(campaignRepository.tooltipsList).to(beEmpty())
                    }

                    it("will remove not existing campaigns") {
                        var tooltips = [tooltip, testTooltip]
                        syncRepository(with: tooltips)
                        expect(campaignRepository.list).to(haveCount(2))

                        tooltips.removeLast()
                        syncRepository(with: tooltips)
                        expect(campaignRepository.list).to(haveCount(1))
                    }

                    it("will persist impressionsLeft value") {
                        syncRepository(with: [tooltip])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: tooltip.id)
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))

                        syncRepository(with: [tooltip])
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))
                    }

                    it("will persist impressionsLeft value for test campaigns") {
                        syncRepository(with: [testTooltip])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: testTooltip.id)
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))

                        syncRepository(with: [testTooltip])
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))
                    }

                    it("will not override impressionsLeft value even if maxImpressions number is smaller") {
                        syncRepository(with: [tooltip])
                        campaignRepository.incrementImpressionsLeftInCampaign(id: tooltip.id)
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))

                        syncRepository(with: [tooltip])
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                    }

                    it("will modify impressionsLeft if maxImpressions value is different (campaign modification)") {
                        syncRepository(with: [tooltip])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: tooltip.id)
                        campaignRepository.decrementImpressionsLeftInCampaign(id: tooltip.id)
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(1))

                        let updatedTooltip = TestHelpers.generateCampaign(id: tooltip.id,
                                                                          maxImpressions: 6,
                                                                          test: false)
                        syncRepository(with: [updatedTooltip])
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                    }

                    it("will save updated list to the cache (anonymous user)") {
                        syncRepository(with: [tooltip])
                        expect(userDataCache.cachedCampaignData).to(equal([tooltip]))
                    }

                    it("will save updated list to the cache (logged-in user)") {
                        userInfoProvider.userID = "user"
                        syncRepository(with: [tooltip])
                        expect(userCache?.campaignData).to(equal([tooltip]))
                    }

                    it("will save test tooltip campaigns to the cache") {
                        userInfoProvider.userID = "user"
                        syncRepository(with: [testTooltip])
                        expect(userCache?.campaignData).to(equal([testTooltip]))
                    }
                }
            }

            context("when optOutCampaign is called") {

                it("will mark campaign as opted out") {
                    syncRepository(with: [campaign])
                    expect(firstPersistedCampaign?.isOptedOut).to(beFalse())

                    let updatedCampaign = campaignRepository.optOutCampaign(campaign)
                    expect(updatedCampaign?.isOptedOut).to(beTrue())
                    expect(firstPersistedCampaign?.isOptedOut).to(beTrue())
                }

                it("will mark test campaign as opted out") {
                    syncRepository(with: [testCampaign])
                    expect(firstPersistedCampaign?.isOptedOut).to(beFalse())

                    let updatedCampaign = campaignRepository.optOutCampaign(testCampaign)
                    expect(updatedCampaign?.isOptedOut).to(beTrue())
                    expect(firstPersistedCampaign?.isOptedOut).to(beTrue())
                }

                it("will save updated list to the cache (anonymous user)") {
                    syncRepository(with: [campaign])
                    campaignRepository.optOutCampaign(campaign)
                    expect(userDataCache.cachedCampaignData?.first?.isOptedOut).to(beTrue())
                }

                it("will save updated list to the cache (logged-in user)") {
                    userInfoProvider.userID = "user"
                    syncRepository(with: [campaign])
                    campaignRepository.optOutCampaign(campaign)
                    expect(userCache?.campaignData?.first?.isOptedOut).to(beTrue())
                }

                it("will NOT cache updated campaign if it's marked as `isTest`") {
                    userInfoProvider.userID = "user"
                    syncRepository(with: [testCampaign])
                    campaignRepository.optOutCampaign(testCampaign)
                    expect(userCache?.campaignData?.first?.isOptedOut).to(beFalse())
                }
            }

            context("when decrementImpressionsLeftInCampaign is called") {
                context("on a campaign") {

                    it("will decrement campaign's impressionsLeft value") {
                        syncRepository(with: [campaign])
                        let impressionsLeft = firstPersistedCampaign?.impressionsLeft ?? 0

                        let updatedCampaign = campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
                        expect(updatedCampaign?.impressionsLeft).to(equal(impressionsLeft - 1))
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(impressionsLeft - 1))
                    }

                    it("will decrement test campaign's impressionsLeft value") {
                        syncRepository(with: [testCampaign])
                        let impressionsLeft = firstPersistedCampaign?.impressionsLeft ?? 0

                        let updatedCampaign = campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
                        expect(updatedCampaign?.impressionsLeft).to(equal(impressionsLeft - 1))
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(impressionsLeft - 1))
                    }

                    it("will not decrement campaign's impressionsLeft value if it's already 0") {
                        let testCampaign = TestHelpers.generateCampaign(id: "testImpressions",
                                                                        maxImpressions: 0,
                                                                        test: false)
                        syncRepository(with: [testCampaign])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)

                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(0))
                    }

                    it("will save updated list to the cache (anonymous user)") {
                        syncRepository(with: [campaign])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
                        expect(userDataCache.cachedCampaignData?.first?.impressionsLeft).to(equal(campaign.impressionsLeft - 1))
                    }

                    it("will save updated list to the cache (logged-in user)") {
                        userInfoProvider.userID = "user"
                        syncRepository(with: [campaign])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
                        expect(userCache?.campaignData?.first?.impressionsLeft).to(equal(campaign.impressionsLeft - 1))
                    }

                    it("will save updated campaign even if it's marked as `isTest`") {
                        userInfoProvider.userID = "user"
                        syncRepository(with: [testCampaign])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
                        expect(userCache?.campaignData?.first?.impressionsLeft).to(equal(2))
                    }
                }

                context("on a tooltip") {

                    it("will decrement tooltips's impressionsLeft value") {
                        syncRepository(with: [tooltip])
                        let impressionsLeft = firstPersistedCampaign?.impressionsLeft ?? 0

                        let updatedCampaign = campaignRepository.decrementImpressionsLeftInCampaign(id: tooltip.id)
                        expect(updatedCampaign?.impressionsLeft).to(equal(impressionsLeft - 1))
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(impressionsLeft - 1))
                    }

                    it("will decrement test tooltips's impressionsLeft value") {
                        syncRepository(with: [testTooltip])
                        let impressionsLeft = firstPersistedCampaign?.impressionsLeft ?? 0

                        let updatedCampaign = campaignRepository.decrementImpressionsLeftInCampaign(id: testTooltip.id)
                        expect(updatedCampaign?.impressionsLeft).to(equal(impressionsLeft - 1))
                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(impressionsLeft - 1))
                    }

                    it("will not decrement tooltips's impressionsLeft value if it's already 0") {
                        let testTooltip = TestHelpers.generateTooltip(id: "testImpressions",
                                                                      isTest: false,
                                                                      maxImpressions: 0)
                        syncRepository(with: [testTooltip])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: testTooltip.id)

                        expect(firstPersistedCampaign?.impressionsLeft).to(equal(0))
                    }

                    it("will save updated list to the cache (anonymous user)") {
                        syncRepository(with: [tooltip])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: tooltip.id)
                        expect(userDataCache.cachedCampaignData?.first?.impressionsLeft).to(equal(tooltip.impressionsLeft - 1))
                    }

                    it("will save updated list to the cache (logged-in user)") {
                        userInfoProvider.userID = "user"
                        syncRepository(with: [tooltip])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: tooltip.id)
                        expect(userCache?.campaignData?.first?.impressionsLeft).to(equal(tooltip.impressionsLeft - 1))
                    }

                    it("will save updated campaign even if it's marked as `isTest`") {
                        userInfoProvider.userID = "user"
                        syncRepository(with: [testTooltip])
                        campaignRepository.decrementImpressionsLeftInCampaign(id: testTooltip.id)
                        expect(userCache?.campaignData?.first?.impressionsLeft).to(equal(2))
                    }
                }
            }

            context("when incrementImpressionsLeftInCampaign is called") {

                it("will increment campaign's impressionsLeft value") {
                    syncRepository(with: [campaign])
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(3))

                    let updatedCampaign = campaignRepository.incrementImpressionsLeftInCampaign(id: campaign.id)
                    expect(updatedCampaign?.impressionsLeft).to(equal(4))
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                }

                it("will increment test campaign's impressionsLeft value") {
                    syncRepository(with: [testCampaign])
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(3))

                    let updatedCampaign = campaignRepository.incrementImpressionsLeftInCampaign(id: testCampaign.id)
                    expect(updatedCampaign?.impressionsLeft).to(equal(4))
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                }

                it("will save updated list to the cache (anonymous user)") {
                    syncRepository(with: [campaign])
                    campaignRepository.incrementImpressionsLeftInCampaign(id: campaign.id)
                    expect(userDataCache.cachedCampaignData?.first?.impressionsLeft).to(equal(campaign.impressionsLeft + 1))
                }

                it("will save updated list to the cache (logged-in user)") {
                    userInfoProvider.userID = "user"
                    syncRepository(with: [campaign])
                    campaignRepository.incrementImpressionsLeftInCampaign(id: campaign.id)
                    expect(userCache?.campaignData?.first?.impressionsLeft).to(equal(campaign.impressionsLeft + 1))
                }

                it("will save updated campaign even if it's marked as `isTest`") {
                    userInfoProvider.userID = "user"
                    syncRepository(with: [testCampaign])
                    campaignRepository.incrementImpressionsLeftInCampaign(id: testCampaign.id)
                    expect(userCache?.campaignData?.first?.impressionsLeft).to(equal(4))
                }
            }

            context("when loadCache is called") {

                let otherCampaign = TestHelpers.generateCampaign(id: "test2", maxImpressions: 3)

                beforeEach {
                    userDataCache.userDataMock = UserDataCacheContainer(campaignData: [campaign, tooltip])
                }

                it("will populate campaign list from cache data") {
                    expect(campaignRepository.list).to(beEmpty())
                    campaignRepository.loadCachedData()
                    expect(campaignRepository.list).to(elementsEqualOrderAgnostic([campaign, tooltip]))
                }

                it("will replace existing data in the repository") {
                    syncRepository(with: [otherCampaign])
                    expect(campaignRepository.list).to(elementsEqual([otherCampaign]))
                    campaignRepository.loadCachedData()
                    expect(campaignRepository.list).to(haveCount(2))
                    expect(campaignRepository.list).toNot(contain(otherCampaign))
                }
            }
        }
    }
}
