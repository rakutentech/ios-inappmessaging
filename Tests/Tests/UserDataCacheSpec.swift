import Foundation
import Quick
import Nimble
@testable import RInAppMessaging

class UserDataCacheSpec: QuickSpec {

    override func spec() {

        let userDefaults = UserDefaults(suiteName: "UserDataCacheSpec")!
        let user = [UserIdentifier(type: .userId, identifier: "testUser")]
        let userDefaultsDataKey = "IAM_user_cache"

        afterEach {
            UserDefaults.standard.removePersistentDomain(forName: "UserDataCacheSpec")
        }

        describe("UserDataCache") {

            it("will return nil if no cached data was found") {
                let userCache = UserDataCache(userDefaults: userDefaults)
                expect(userCache.getUserData(identifiers: [])).to(beNil())
            }

            it("will return nil if invalid cached data was found") {
                userDefaults.set("invalid_data".data(using: .utf8), forKey: userDefaultsDataKey)
                let userCache = UserDataCache(userDefaults: userDefaults)
                expect(userCache.getUserData(identifiers: [])).to(beNil())
            }

            it("will return previously cached display permission data") {
                let previousUserCache = UserDataCache(userDefaults: userDefaults)
                let displayPermissionData = DisplayPermissionResponse(display: true, performPing: false)
                let campaign = TestHelpers.generateCampaign(id: "test")
                previousUserCache.cacheDisplayPermissionData(displayPermissionData, campaignID: campaign.id, userIdentifiers: [])

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
                userCache.cacheDisplayPermissionData(dpDataA, campaignID: campaignA.id, userIdentifiers: [])
                userCache.cacheDisplayPermissionData(dpDataB, campaignID: campaignB.id, userIdentifiers: [])

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

            it("will not return registered user data from anonymous user container") {
                let previousUserCache = UserDataCache(userDefaults: userDefaults)
                let campaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 0).data
                previousUserCache.cacheCampaignData(campaigns, userIdentifiers: [])

                let userCache = UserDataCache(userDefaults: userDefaults)
                let userContainer = userCache.getUserData(identifiers: user)
                expect(userContainer).to(beNil())
            }

            it("will remove all user cached data for registered user") {
                let userCache = UserDataCache(userDefaults: userDefaults)
                let userIdentifier = [UserIdentifier(type: .userId, identifier: "testUser")]

                let campaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 0).data
                userCache.cacheCampaignData(campaigns, userIdentifiers: userIdentifier)
                let displayPermission = DisplayPermissionResponse(display: true, performPing: false)
                userCache.cacheDisplayPermissionData(displayPermission, campaignID: campaigns[0].id, userIdentifiers: userIdentifier)

                userCache.deleteUserData(identifiers: userIdentifier)
                let userContainer = userCache.getUserData(identifiers: userIdentifier)

                expect(userContainer?.campaignData).to(beNil())
                expect(userContainer?.displayPermissionData(for: campaigns[0])).to(beNil())
            }

            context("when two threads call cacheCampaignData") {
                it("will not crash") {
                    let queue1 = DispatchQueue(label: "UserDataCacheQueue1")
                    let queue2 = DispatchQueue(label: "UserDataCacheQueue2")
                    let userCache = UserDataCache(userDefaults: UserDefaults(suiteName: "UserDataCacheForQueue")!)
                    var queue1IsDone = false
                    var queue2IsDone = false
                    queue1.async {
                        for _ in 1...1000 {
                            userCache.cacheCampaignData([], userIdentifiers: [])
                        }
                        DispatchQueue.main.async { queue1IsDone = true }
                    }
                    queue2.async {
                        for _ in 1...1000 {
                            userCache.cacheCampaignData([], userIdentifiers: [])
                        }
                        DispatchQueue.main.async { queue2IsDone = true }
                    }
                    expect(queue1IsDone).toEventually(beTrue(), timeout: .seconds(2))
                    expect(queue2IsDone).toEventually(beTrue(), timeout: .seconds(2))
                }

                afterEach {
                    UserDefaults.standard.removePersistentDomain(forName: "UserDataCacheForQueue")
                }
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

                it("will use separate containers for different idTrackingIds") {
                    let userA = [UserIdentifier(type: .idTrackingIdentifier, identifier: "idTrackingId1")]
                    let userB = [UserIdentifier(type: .idTrackingIdentifier, identifier: "idTrackingId2")]
                    userCache.cacheCampaignData(campaignsDataA, userIdentifiers: userA)
                    userCache.cacheCampaignData(campaignsDataB, userIdentifiers: userB)

                    expect(userCache.getUserData(identifiers: userA)).toNot(equal(userCache.getUserData(identifiers: userB)))
                }

                it("will use separate containers for the same userId with different idTrackingId") {
                    let userA = [UserIdentifier(type: .userId, identifier: "userId1"),
                                 UserIdentifier(type: .idTrackingIdentifier, identifier: "idTrackingId1")]
                    let userB = [UserIdentifier(type: .userId, identifier: "userId1"),
                                 UserIdentifier(type: .idTrackingIdentifier, identifier: "idTrackingId2")]
                    userCache.cacheCampaignData(campaignsDataA, userIdentifiers: userA)
                    userCache.cacheCampaignData(campaignsDataB, userIdentifiers: userB)

                    expect(userCache.getUserData(identifiers: userA)).toNot(equal(userCache.getUserData(identifiers: userB)))
                }

                it("will use separate containers for the same idTrackingId if also other id is present in one of them") {
                    let userA = [UserIdentifier(type: .userId, identifier: "userId1"),
                                 UserIdentifier(type: .idTrackingIdentifier, identifier: "idTrackingId1")]
                    let userB = [UserIdentifier(type: .userId, identifier: "userId1")]
                    userCache.cacheCampaignData(campaignsDataA, userIdentifiers: userA)
                    userCache.cacheCampaignData(campaignsDataB, userIdentifiers: userB)

                    expect(userCache.getUserData(identifiers: userA)).toNot(equal(userCache.getUserData(identifiers: userB)))
                }
            }
        }
    }
}
