import Quick
import Nimble
@testable import RInAppMessaging

class CampaignRepositorySpec: QuickSpec {

    override func spec() {
        describe("CampaignRepository") {

            var campaignRepository: CampaignRepository!
            var userDataCache: UserDataCacheMock!
            var preferenceRepository: IAMPreferenceRepository!
            var firstPersistedCampaign: Campaign? {
                return campaignRepository.list.first
            }
            let testCampaign = TestHelpers.generateCampaign(id: "testImpressions",
                                                            test: false,
                                                            delay: 0,
                                                            maxImpressions: 3)

            func insertRandomCampaigns() {
                let campaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 1).data
                campaignRepository.syncWith(list: campaigns, timestampMilliseconds: 0)
            }

            beforeEach {
                userDataCache = UserDataCacheMock()
                preferenceRepository = IAMPreferenceRepository()
                campaignRepository = CampaignRepository(userDataCache: userDataCache, preferenceRepository: preferenceRepository)
            }

            it("will load default user cache data during initialization") {
                userDataCache.defaultUserDataMock = UserDataCacheContainer(campaignData: [testCampaign])
                campaignRepository = CampaignRepository(userDataCache: userDataCache, preferenceRepository: IAMPreferenceRepository())
                expect(campaignRepository.list).to(equal([testCampaign]))
            }

            context("when syncing") {

                it("will add new campaigns to the list") {
                    insertRandomCampaigns()
                    let newCampaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 1).data
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
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))

                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))
                }

                it("will persist isOptedOut value") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.isOptedOut).to(beFalse())

                    campaignRepository.optOutCampaign(testCampaign)
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.isOptedOut).to(beTrue())
                }

                it("will not override impressionsLeft value even if maxImpressions number is smaller") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.incrementImpressionsLeftInCampaign(id: testCampaign.id)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))

                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                }

                it("will modify impressionsLeft if maxImpressions value is different (campaign modification)") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
                    campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(1))

                    let updatedCampaign = TestHelpers.generateCampaign(id: "testImpressions",
                                                                    test: false,
                                                                    delay: 0,
                                                                    maxImpressions: 6)
                    campaignRepository.syncWith(list: [updatedCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                }

                it("will save updated list to the cache (anonymous user)") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(userDataCache.cachedCampaignData).to(equal([testCampaign]))
                }

                it("will save updated list to the cache (logged-in user)") {
                    preferenceRepository.setPreference(IAMPreferenceBuilder().setUserId("user").build())
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    let userCache = userDataCache.cachedData[preferenceRepository.getUserIdentifiers()]
                    let defaultUserCache = userDataCache.cachedData[[]]
                    expect(userCache?.campaignData).to(equal([testCampaign]))
                    expect(defaultUserCache?.campaignData).to(equal(userCache?.campaignData))
                }
            }

            context("when optOutCampaign is called") {

                it("will mark campaign as opted out") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.isOptedOut).to(beFalse())

                    campaignRepository.optOutCampaign(testCampaign)
                    expect(firstPersistedCampaign?.isOptedOut).to(beTrue())
                }

                it("will save updated list to the cache (anonymous user)") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.optOutCampaign(testCampaign)
                    expect(userDataCache.cachedCampaignData?.first?.isOptedOut).to(beTrue())
                }

                it("will save updated list to the cache (logged-in user)") {
                    preferenceRepository.setPreference(IAMPreferenceBuilder().setUserId("user").build())
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.optOutCampaign(testCampaign)
                    let userCache = userDataCache.cachedData[preferenceRepository.getUserIdentifiers()]
                    let defaultUserCache = userDataCache.cachedData[[]]
                    expect(userCache?.campaignData?.first?.isOptedOut).to(beTrue())
                    expect(defaultUserCache?.campaignData).to(equal(userCache?.campaignData))
                }
            }

            context("when decrementImpressionsLeftInCampaign is called") {

                it("will decrement campaign's impressionsLeft value") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    let impressionsLeft = firstPersistedCampaign?.impressionsLeft ?? 0

                    campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
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
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
                    expect(userDataCache.cachedCampaignData?.first?.impressionsLeft).to(equal(testCampaign.impressionsLeft - 1))
                }

                it("will save updated list to the cache (logged-in user)") {
                    preferenceRepository.setPreference(IAMPreferenceBuilder().setUserId("user").build())
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
                    let userCache = userDataCache.cachedData[preferenceRepository.getUserIdentifiers()]
                    let defaultUserCache = userDataCache.cachedData[[]]
                    expect(userCache?.campaignData?.first?.impressionsLeft).to(equal(testCampaign.impressionsLeft - 1))
                    expect(defaultUserCache?.campaignData).to(equal(userCache?.campaignData))
                }
            }

            context("when incrementImpressionsLeftInCampaign is called") {

                it("will increment campaign's impressionsLeft value") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(3))

                    campaignRepository.incrementImpressionsLeftInCampaign(id: testCampaign.id)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                }

                it("will save updated list to the cache (anonymous user)") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.incrementImpressionsLeftInCampaign(id: testCampaign.id)
                    expect(userDataCache.cachedCampaignData?.first?.impressionsLeft).to(equal(testCampaign.impressionsLeft + 1))
                }

                it("will save updated list to the cache (logged-in user)") {
                    preferenceRepository.setPreference(IAMPreferenceBuilder().setUserId("user").build())
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.incrementImpressionsLeftInCampaign(id: testCampaign.id)
                    let userCache = userDataCache.cachedData[preferenceRepository.getUserIdentifiers()]
                    let defaultUserCache = userDataCache.cachedData[[]]
                    expect(userCache?.campaignData?.first?.impressionsLeft).to(equal(testCampaign.impressionsLeft + 1))
                    expect(defaultUserCache?.campaignData).to(equal(userCache?.campaignData))
                }
            }

            context("when loadCache is called") {
                context("and no user is logged in (default user cache)") {

                    beforeEach {
                        userDataCache.defaultUserDataMock = UserDataCacheContainer(campaignData: [testCampaign])
                        userDataCache.userDataMock = nil
                        preferenceRepository.setPreference(nil)
                    }

                    context("and syncWithDefaultUserData set to false") {

                        it("will populate campaign list from cache data") {
                            expect(campaignRepository.list).to(beEmpty())
                            campaignRepository.loadCachedData(syncWithDefaultUserData: false)
                            expect(campaignRepository.list).to(haveCount(1))
                        }

                        it("will clear old campaign list if there is no cache data") {
                            campaignRepository.loadCachedData(syncWithDefaultUserData: false)
                            expect(campaignRepository.list).to(haveCount(1))
                            userDataCache.defaultUserDataMock = nil
                            campaignRepository.loadCachedData(syncWithDefaultUserData: false)
                            expect(campaignRepository.list).to(beEmpty())
                        }
                    }

                    context("and syncWithDefaultUserData set to true") {

                        it("will populate campaign list from cache data") {
                            userDataCache.userDataMock = UserDataCacheContainer(campaignData: [testCampaign])
                            expect(campaignRepository.list).to(beEmpty())
                            campaignRepository.loadCachedData(syncWithDefaultUserData: true)
                            expect(campaignRepository.list).to(haveCount(1))
                        }
                    }
                }

                context("and user is logged in") {
                    let modifiedTestCampaign = TestHelpers.generateCampaign(id: "testImpressions",
                                                                            test: false,
                                                                            delay: 0,
                                                                            maxImpressions: 0)
                    let otherTestCampaign = TestHelpers.generateCampaign(id: "test2",
                                                                         test: false,
                                                                         delay: 0,
                                                                         maxImpressions: 3)

                    beforeEach {
                        preferenceRepository.setPreference(IAMPreferenceBuilder().setUserId("user").build())
                    }

                    context("and syncWithDefaultUserData set to false") {

                        beforeEach {
                            userDataCache.defaultUserDataMock = UserDataCacheContainer(campaignData: [modifiedTestCampaign, otherTestCampaign])
                            userDataCache.userDataMock = nil
                        }

                        it("will not populate campaign list from cache data") {
                            expect(campaignRepository.list).to(beEmpty())
                            campaignRepository.loadCachedData(syncWithDefaultUserData: false)
                            expect(campaignRepository.list).to(beEmpty())
                        }

                        it("will clear old campaign list if there is no cache data") {
                            userDataCache.userDataMock = UserDataCacheContainer(campaignData: [testCampaign])
                            campaignRepository.loadCachedData(syncWithDefaultUserData: false)
                            expect(campaignRepository.list).to(haveCount(1))
                            userDataCache.userDataMock = nil
                            campaignRepository.loadCachedData(syncWithDefaultUserData: false)
                            expect(campaignRepository.list).to(beEmpty())
                        }
                    }

                    context("and syncWithDefaultUserData set to true") {

                        it("will populate campaign list from cache data if default user cache is empty") {
                            userDataCache.defaultUserDataMock = nil
                            userDataCache.userDataMock = UserDataCacheContainer(campaignData: [testCampaign])
                            campaignRepository.loadCachedData(syncWithDefaultUserData: true)
                            expect(campaignRepository.list).to(elementsEqual([testCampaign]))
                        }

                        it("will populate campaign list from default cache data if user cache is empty") {
                            userDataCache.defaultUserDataMock = UserDataCacheContainer(campaignData: [testCampaign])
                            userDataCache.userDataMock = nil
                            campaignRepository.loadCachedData(syncWithDefaultUserData: true)
                            expect(campaignRepository.list).to(elementsEqual([testCampaign]))
                        }

                        it("will populate campaign list from cache data and add new campaings from default user cache") {
                            userDataCache.defaultUserDataMock = UserDataCacheContainer(campaignData: [otherTestCampaign])
                            userDataCache.userDataMock = UserDataCacheContainer(campaignData: [testCampaign])
                            campaignRepository.loadCachedData(syncWithDefaultUserData: true)
                            expect(campaignRepository.list).to(equal([testCampaign, otherTestCampaign]))
                        }

                        it("will populate campaign list from cache data and update campaings from default user cache") {
                            userDataCache.defaultUserDataMock = UserDataCacheContainer(campaignData: [modifiedTestCampaign])
                            userDataCache.userDataMock = UserDataCacheContainer(campaignData: [testCampaign])
                            campaignRepository.loadCachedData(syncWithDefaultUserData: true)
                            expect(campaignRepository.list).to(elementsEqual([modifiedTestCampaign]))
                        }
                    }
                }
            }
        }
    }
}
