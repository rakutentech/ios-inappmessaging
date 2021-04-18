import Quick
import Nimble
@testable import RInAppMessaging

class UserDataCacheSpec: QuickSpec {

    override func spec() {

        let userDefaults = UserDefaults(suiteName: "UserDataCacheSpec")!
        let user = [UserIdentifier(type: .userId, identifier: "testUser")]

        afterEach {
            UserDefaults.standard.removePersistentDomain(forName: "UserDataCacheSpec")
        }

        describe("UserDataCache") {

            it("will return nil if no cached data was found") {
                let userCache = UserDataCache(userDefaults: userDefaults)
                expect(userCache.getUserData(identifiers: [])).to(beNil())
            }

            it("will return previously cached display permission data") {
                let previousUserCache = UserDataCache(userDefaults: userDefaults)
                let displayPermissionData = DisplayPermissionResponse(display: true, performPing: false)
                let campaign = TestHelpers.generateCampaign(id: "test")
                previousUserCache.cacheDisplayPermissionData(displayPermissionData, for: campaign, userIdentifiers: [])

                let userCache = UserDataCache(userDefaults: userDefaults)
                let userContainer = userCache.getUserData(identifiers: [])
                expect(userContainer).toNot(beNil())
                expect(userContainer?.displayPermissionData(for: campaign)).to(equal(displayPermissionData))
            }

            it("will store separate display permission data for each campaign") {
                let userCache = UserDataCache(userDefaults: userDefaults)
                let dpDataA = DisplayPermissionResponse(display: true, performPing: false)
                let dpDataB = DisplayPermissionResponse(display: false, performPing: false) // creationTimeMilliseconds is also different
                let campaignA = TestHelpers.generateCampaign(id: "test1")
                let campaignB = TestHelpers.generateCampaign(id: "test2")
                userCache.cacheDisplayPermissionData(dpDataA, for: campaignA, userIdentifiers: [])
                userCache.cacheDisplayPermissionData(dpDataB, for: campaignB, userIdentifiers: [])

                let userContainer = userCache.getUserData(identifiers: [])
                expect(userContainer?.displayPermissionData(for: campaignA)).toNot(equal(userContainer?.displayPermissionData(for: campaignB)))
            }

            it("will return previously cached campaign data") {
                let previousUserCache = UserDataCache(userDefaults: userDefaults)
                let campaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 0).data
                previousUserCache.cacheCampaignData(campaigns, userIdentifiers: [])

                let userCache = UserDataCache(userDefaults: userDefaults)
                let userContainer = userCache.getUserData(identifiers: [])
                expect(userContainer).toNot(beNil())
                expect(userContainer?.campaignData).to(equal(campaigns))
            }

            it("will return previously cached data for registered user") {
                let previousUserCache = UserDataCache(userDefaults: userDefaults)
                let campaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 0).data
                previousUserCache.cacheCampaignData(campaigns, userIdentifiers: user)

                let userCache = UserDataCache(userDefaults: userDefaults)
                let userContainer = userCache.getUserData(identifiers: user)
                expect(userContainer).toNot(beNil())
                expect(userContainer?.campaignData).to(equal(campaigns))
            }

            it("will not return data from anonymous user container") {
                let previousUserCache = UserDataCache(userDefaults: userDefaults)
                let campaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 0).data
                previousUserCache.cacheCampaignData(campaigns, userIdentifiers: [])

                let userCache = UserDataCache(userDefaults: userDefaults)
                let userContainer = userCache.getUserData(identifiers: user)
                expect(userContainer).to(beNil())
            }

            context("when creating a container for given user identifiers combination") {
                let campaignsDataA = [TestHelpers.generateCampaign(id: "test1")]
                let campaignsDataB = [TestHelpers.generateCampaign(id: "test2")]
                var userCache: UserDataCache!

                beforeEach {
                    userCache = UserDataCache(userDefaults: userDefaults)
                }

                it("will use separate containers for different userIds") {
                    let userA = [UserIdentifier(type: .userId, identifier: "userId1")]
                    let userB = [UserIdentifier(type: .userId, identifier: "userId2")]
                    userCache.cacheCampaignData(campaignsDataA, userIdentifiers: userA)
                    userCache.cacheCampaignData(campaignsDataB, userIdentifiers: userB)

                    expect(userCache.getUserData(identifiers: userA)).toNot(equal(userCache.getUserData(identifiers: userB)))
                }

                it("will use separate containers for different rakutenIds") {
                    let userA = [UserIdentifier(type: .rakutenId, identifier: "rakutenId1")]
                    let userB = [UserIdentifier(type: .rakutenId, identifier: "rakutenId2")]
                    userCache.cacheCampaignData(campaignsDataA, userIdentifiers: userA)
                    userCache.cacheCampaignData(campaignsDataB, userIdentifiers: userB)

                    expect(userCache.getUserData(identifiers: userA)).toNot(equal(userCache.getUserData(identifiers: userB)))
                }

                it("will use separate containers for the same userId with different rakutenId") {
                    let userA = [UserIdentifier(type: .userId, identifier: "userId1"), UserIdentifier(type: .rakutenId, identifier: "rakutenId1")]
                    let userB = [UserIdentifier(type: .userId, identifier: "userId1"), UserIdentifier(type: .rakutenId, identifier: "rakutenId2")]
                    userCache.cacheCampaignData(campaignsDataA, userIdentifiers: userA)
                    userCache.cacheCampaignData(campaignsDataB, userIdentifiers: userB)

                    expect(userCache.getUserData(identifiers: userA)).toNot(equal(userCache.getUserData(identifiers: userB)))
                }

                it("will use separate containers for the same rakutenId if also other id is present in one of them") {
                    let userA = [UserIdentifier(type: .userId, identifier: "userId1"), UserIdentifier(type: .rakutenId, identifier: "rakutenId1")]
                    let userB = [UserIdentifier(type: .userId, identifier: "userId1")]
                    userCache.cacheCampaignData(campaignsDataA, userIdentifiers: userA)
                    userCache.cacheCampaignData(campaignsDataB, userIdentifiers: userB)

                    expect(userCache.getUserData(identifiers: userA)).toNot(equal(userCache.getUserData(identifiers: userB)))
                }

                it("will use the same container for the same (userId, rakutenId) set") {
                    let userA = [UserIdentifier(type: .userId, identifier: "userId1"), UserIdentifier(type: .rakutenId, identifier: "rakutenId2")]
                    let userB = [UserIdentifier(type: .rakutenId, identifier: "rakutenId2"), UserIdentifier(type: .userId, identifier: "userId1")]
                    userCache.cacheCampaignData(campaignsDataA, userIdentifiers: userA)

                    expect(userCache.getUserData(identifiers: userA)).to(equal(userCache.getUserData(identifiers: userB)))
                }
            }
        }
    }
}
