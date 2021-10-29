import Quick
import Nimble
@testable import RInAppMessaging

class CampaignRepositorySpec: QuickSpec {

    override func spec() {
        describe("CampaignRepository") {

            var campaignRepository: CampaignRepository!
            var userDataCache: UserDataCacheMock!
            var accountRepository: AccountRepositoryType!
            var firstPersistedCampaign: Campaign? {
                return campaignRepository.list.first
            }
            var userCache: UserDataCacheContainer? {
                userDataCache.cachedData[accountRepository.getUserIdentifiers()]
            }
            var lastUserCache: UserDataCacheContainer? {
                userDataCache.cachedData[CampaignRepository.lastUser]
            }
            let userInfoProvider = UserInfoProviderMock()
            let campaign = TestHelpers.generateCampaign(id: "campaign-id",
                                                        test: false,
                                                        delay: 0,
                                                        maxImpressions: 3)
            let testCampaign = TestHelpers.generateCampaign(id: "test-campaign-id",
                                                            test: true,
                                                            delay: 0,
                                                            maxImpressions: 3)

            func insertRandomCampaigns() {
                let campaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 1).data
                campaignRepository.syncWith(list: campaigns, timestampMilliseconds: 0)
            }

            beforeEach {
                userInfoProvider.clear()
                userDataCache = UserDataCacheMock()
                accountRepository = AccountRepository(userDataCache: userDataCache)
                accountRepository.setPreference(userInfoProvider)
                campaignRepository = CampaignRepository(userDataCache: userDataCache, accountRepository: accountRepository)
            }

            it("will load last user cache data during initialization") {
                userDataCache.lastUserDataMock = UserDataCacheContainer(campaignData: [campaign])
                let campaignRepository = CampaignRepository(userDataCache: userDataCache, accountRepository: accountRepository)
                expect(campaignRepository.list).to(equal([campaign]))
            }

            context("when syncing") {

                it("will add new campaigns to the list") {
                    insertRandomCampaigns()
                    let newCampaigns = [campaign, testCampaign]
                    campaignRepository.syncWith(list: newCampaigns, timestampMilliseconds: 0)
                    expect(campaignRepository.list).to(contain(newCampaigns))
                }

                it("will remove not existing campaigns") {
                    var campaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 1).data
                    campaignRepository.syncWith(list: campaigns, timestampMilliseconds: 0)
                    expect(campaignRepository.list).to(haveCount(2))

                    campaigns.removeLast()
                    campaignRepository.syncWith(list: campaigns, timestampMilliseconds: 0)
                    expect(campaignRepository.list).to(haveCount(1))
                }

                it("will persist impressionsLeft value") {
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))

                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))
                }

                it("will not persist impressionsLeft value for test campaigns") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))

                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(3))
                }

                it("will persist isOptedOut value") {
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.isOptedOut).to(beFalse())

                    campaignRepository.optOutCampaign(campaign)
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.isOptedOut).to(beTrue())
                }

                it("will not override impressionsLeft value even if maxImpressions number is smaller") {
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    campaignRepository.incrementImpressionsLeftInCampaign(id: campaign.id)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))

                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                }

                it("will modify impressionsLeft if maxImpressions value is different (campaign modification)") {
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
                    campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(1))

                    let updatedCampaign = TestHelpers.generateCampaign(id: campaign.id,
                                                                       test: false,
                                                                       delay: 0,
                                                                       maxImpressions: 6)
                    campaignRepository.syncWith(list: [updatedCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                }

                it("will save updated list to the cache (anonymous user)") {
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(userDataCache.cachedCampaignData).to(equal([campaign]))
                    expect(lastUserCache?.campaignData).to(equal(userCache?.campaignData))
                }

                it("will save updated list to the cache (logged-in user)") {
                    userInfoProvider.userID = "user"
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(userCache?.campaignData).to(equal([campaign]))
                    expect(lastUserCache?.campaignData).to(equal(userCache?.campaignData))
                }

                it("will not save test campaigns to the cache") {
                    userInfoProvider.userID = "user"
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(userCache?.campaignData).toNot(equal([testCampaign]))
                    expect(lastUserCache?.campaignData).to(equal(userCache?.campaignData))
                }
            }

            context("when optOutCampaign is called") {

                it("will mark campaign as opted out") {
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.isOptedOut).to(beFalse())

                    let updatedCampaign = campaignRepository.optOutCampaign(campaign)
                    expect(updatedCampaign?.isOptedOut).to(beTrue())
                    expect(firstPersistedCampaign?.isOptedOut).to(beTrue())
                }

                it("will mark test campaign as opted out") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.isOptedOut).to(beFalse())

                    let updatedCampaign = campaignRepository.optOutCampaign(testCampaign)
                    expect(updatedCampaign?.isOptedOut).to(beTrue())
                    expect(firstPersistedCampaign?.isOptedOut).to(beTrue())
                }

                it("will save updated list to the cache (anonymous user)") {
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    campaignRepository.optOutCampaign(campaign)
                    expect(userDataCache.cachedCampaignData?.first?.isOptedOut).to(beTrue())
                    expect(lastUserCache?.campaignData).to(equal(userCache?.campaignData))
                }

                it("will save updated list to the cache (logged-in user)") {
                    userInfoProvider.userID = "user"
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    campaignRepository.optOutCampaign(campaign)
                    expect(userCache?.campaignData?.first?.isOptedOut).to(beTrue())
                    expect(lastUserCache?.campaignData).to(equal(userCache?.campaignData))
                }

                it("will NOT save updated list to the cache if campaign is marked as `isTest`") {
                    userInfoProvider.userID = "user"
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.optOutCampaign(testCampaign)
                    expect(userCache?.campaignData).to(beEmpty())
                    expect(lastUserCache?.campaignData).to(beEmpty())
                }
            }

            context("when decrementImpressionsLeftInCampaign is called") {

                it("will decrement campaign's impressionsLeft value") {
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    let impressionsLeft = firstPersistedCampaign?.impressionsLeft ?? 0

                    let updatedCampaign = campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
                    expect(updatedCampaign?.impressionsLeft).to(equal(impressionsLeft - 1))
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(impressionsLeft - 1))
                }

                it("will decrement test campaign's impressionsLeft value") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    let impressionsLeft = firstPersistedCampaign?.impressionsLeft ?? 0

                    let updatedCampaign = campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
                    expect(updatedCampaign?.impressionsLeft).to(equal(impressionsLeft - 1))
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(impressionsLeft - 1))
                }

                it("will not decrement campaign's impressionsLeft value if it's already 0") {
                    let testCampaign = TestHelpers.generateCampaign(id: "testImpressions",
                                                                    test: false,
                                                                    delay: 0,
                                                                    maxImpressions: 0)
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)

                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(0))
                }

                it("will save updated list to the cache (anonymous user)") {
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
                    expect(userDataCache.cachedCampaignData?.first?.impressionsLeft).to(equal(campaign.impressionsLeft - 1))
                    expect(lastUserCache?.campaignData).to(equal(userCache?.campaignData))
                }

                it("will save updated list to the cache (logged-in user)") {
                    userInfoProvider.userID = "user"
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    campaignRepository.decrementImpressionsLeftInCampaign(id: campaign.id)
                    expect(userCache?.campaignData?.first?.impressionsLeft).to(equal(campaign.impressionsLeft - 1))
                    expect(lastUserCache?.campaignData).to(equal(userCache?.campaignData))
                }

                it("will NOT save updated list to the cache if campaign is marked as `isTest`") {
                    userInfoProvider.userID = "user"
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
                    expect(userCache?.campaignData).to(beEmpty())
                    expect(lastUserCache?.campaignData).to(beEmpty())
                }
            }

            context("when incrementImpressionsLeftInCampaign is called") {

                it("will increment campaign's impressionsLeft value") {
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(3))

                    let updatedCampaign = campaignRepository.incrementImpressionsLeftInCampaign(id: campaign.id)
                    expect(updatedCampaign?.impressionsLeft).to(equal(4))
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                }

                it("will increment test campaign's impressionsLeft value") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(3))

                    let updatedCampaign = campaignRepository.incrementImpressionsLeftInCampaign(id: testCampaign.id)
                    expect(updatedCampaign?.impressionsLeft).to(equal(4))
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                }

                it("will save updated list to the cache (anonymous user)") {
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    campaignRepository.incrementImpressionsLeftInCampaign(id: campaign.id)
                    expect(userDataCache.cachedCampaignData?.first?.impressionsLeft).to(equal(campaign.impressionsLeft + 1))
                    expect(lastUserCache?.campaignData).to(equal(userCache?.campaignData))
                }

                it("will save updated list to the cache (logged-in user)") {
                    userInfoProvider.userID = "user"
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    campaignRepository.incrementImpressionsLeftInCampaign(id: campaign.id)
                    expect(userCache?.campaignData?.first?.impressionsLeft).to(equal(campaign.impressionsLeft + 1))
                    expect(lastUserCache?.campaignData).to(equal(userCache?.campaignData))
                }

                it("will NOT save updated list to the cache if campaign is marked as `isTest`") {
                    userInfoProvider.userID = "user"
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.incrementImpressionsLeftInCampaign(id: testCampaign.id)
                    expect(userCache?.campaignData).to(beEmpty())
                    expect(lastUserCache?.campaignData).to(beEmpty())
                }
            }

            context("when loadCache is called") {

                let modifiedCampaign = TestHelpers.generateCampaign(id: campaign.id,
                                                                    test: false,
                                                                    delay: 0,
                                                                    maxImpressions: 0)
                let otherCampaign = TestHelpers.generateCampaign(id: "test2",
                                                                 test: false,
                                                                 delay: 0,
                                                                 maxImpressions: 3)

                context("and lastUserDataMock is not empty") {

                    beforeEach {
                        userDataCache.lastUserDataMock = UserDataCacheContainer(campaignData: [campaign])
                        userDataCache.userDataMock = nil
                    }

                    context("and syncWithLastUserData set to false") {

                        it("will not populate campaign list from cache data") {
                            expect(campaignRepository.list).to(beEmpty())
                            campaignRepository.loadCachedData(syncWithLastUserData: false)
                            expect(campaignRepository.list).to(beEmpty())
                        }
                    }

                    context("and syncWithDefaultUserData set to true") {

                        it("will populate campaign list from last user cache data") {
                            userDataCache.userDataMock = UserDataCacheContainer(campaignData: [campaign])
                            expect(campaignRepository.list).to(beEmpty())
                            campaignRepository.loadCachedData(syncWithLastUserData: true)
                            expect(campaignRepository.list).to(haveCount(1))
                        }

                        it("will populate campaign list from cache data and add new campaings from last user cache") {
                            userDataCache.lastUserDataMock = UserDataCacheContainer(campaignData: [otherCampaign])
                            userDataCache.userDataMock = UserDataCacheContainer(campaignData: [campaign])
                            campaignRepository.loadCachedData(syncWithLastUserData: true)
                            expect(campaignRepository.list).to(equal([campaign, otherCampaign]))
                        }

                        it("will populate campaign list from cache data and update campaings from last user cache") {
                            userDataCache.lastUserDataMock = UserDataCacheContainer(campaignData: [modifiedCampaign])
                            userDataCache.userDataMock = UserDataCacheContainer(campaignData: [campaign])
                            campaignRepository.loadCachedData(syncWithLastUserData: true)
                            expect(campaignRepository.list).to(elementsEqual([modifiedCampaign]))
                        }
                    }
                }

                context("and lastUserDataMock is empty") {

                    beforeEach {
                        userDataCache.lastUserDataMock = nil
                        userDataCache.userDataMock = UserDataCacheContainer(campaignData: [campaign])
                    }

                    context("and syncWithLastUserData set to false") {

                        it("will populate campaign list from cache data") {
                            expect(campaignRepository.list).to(beEmpty())
                            campaignRepository.loadCachedData(syncWithLastUserData: false)
                            expect(campaignRepository.list).to(haveCount(1))
                        }

                    }

                    context("and syncWithDefaultUserData set to true") {

                        it("will not clear existing campaign list if there is no cache data") {
                            expect(campaignRepository.list).to(beEmpty())
                            campaignRepository.loadCachedData(syncWithLastUserData: true)
                            expect(campaignRepository.list).to(haveCount(1))
                        }
                    }
                }
            }
        }
    }
}
