import Quick
import Nimble
@testable import RInAppMessaging

class ReadyCampaignDispatcherTests: QuickSpec {

    override func spec() {
        describe("ReadyCampaignDispatcher") {
            var dispatcher: ReadyCampaignDispatcher!
            var permissionClient: PermissionClientMock!
            var campaignRepository: CampaignRepositoryMock!
            var router: RouterMock!

            beforeEach {
                permissionClient = PermissionClientMock()
                campaignRepository = CampaignRepositoryMock()
                router = RouterMock()
                dispatcher = ReadyCampaignDispatcher(router: router,
                                                     permissionClient: permissionClient,
                                                     campaignRepository: campaignRepository)
            }

            context("before dispatching") {

                it("won't start dispatching while adding to the queue") {
                    permissionClient.shouldGrantPermission = true
                    let testCampaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 3, test: false, delay: 0).data
                    testCampaigns.forEach {
                        dispatcher.addToQueue(campaign: $0)
                    }
                    waitUntil { done in
                        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                            expect(router.lastDisplayedCampaign).to(beNil())
                            done()
                        }
                    }
                }
            }

            context("while dispatching") {

                context("when display permission is granted") {
                    beforeEach {
                        permissionClient.shouldGrantPermission = true
                    }

                    it("will dispatch newly added campaigns") {
                        let testCampaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 1000).data
                        let firstCampaign = testCampaigns[0]
                        let secondCampaign = testCampaigns[1]
                        dispatcher.addToQueue(campaign: firstCampaign)
                        dispatcher.dispatchAllIfNeeded()
                        dispatcher.addToQueue(campaign: secondCampaign)
                        expect(router.lastDisplayedCampaign).toEventually(equal(secondCampaign), timeout: 2)
                    }

                    it("won't start another dispatch procedure if one has already started") {
                        let testCampaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 8000).data
                        let firstCampaign = testCampaigns[0]
                        let secondCampaign = testCampaigns[1]
                        dispatcher.addToQueue(campaign: firstCampaign)
                        dispatcher.addToQueue(campaign: secondCampaign)
                        dispatcher.dispatchAllIfNeeded()
                        expect(router.lastDisplayedCampaign).toEventually(equal(firstCampaign))
                        dispatcher.dispatchAllIfNeeded()
                        expect(router.lastDisplayedCampaign).toEventuallyNot(equal(secondCampaign))
                    }
                }

                context("when display permission is denied") {
                    beforeEach {
                        permissionClient.shouldGrantPermission = false
                    }

                    it("will always dispatch test campaigns") {
                        let testCampaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: true, delay: 500).data
                        let firstCampaign = testCampaigns[0]
                        let secondCampaign = testCampaigns[1]
                        dispatcher.addToQueue(campaign: firstCampaign)
                        dispatcher.addToQueue(campaign: secondCampaign)
                        dispatcher.dispatchAllIfNeeded()
                        expect(router.lastDisplayedCampaign).toEventually(equal(firstCampaign))
                        expect(router.lastDisplayedCampaign).toEventually(equal(secondCampaign))
                    }

                    it("won't dispatch non-test campaigns") {
                        let campaign = TestHelpers.MockResponse.withGeneratedCampaigns(count: 1, test: false, delay: 0).data[0]
                        dispatcher.addToQueue(campaign: campaign)
                        dispatcher.dispatchAllIfNeeded()
                        waitUntil { done in
                            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                                expect(router.lastDisplayedCampaign).to(beNil())
                                done()
                            }
                        }
                    }
                }
            }

            context("after dispatching") {

                it("will decrement impressions left in campaign") {
                    permissionClient.shouldGrantPermission = true
                    let campaign = TestHelpers.MockResponse.withGeneratedCampaigns(count: 1, test: false, delay: 0).data[0]
                    dispatcher.addToQueue(campaign: campaign)
                    dispatcher.dispatchAllIfNeeded()
                    expect(campaignRepository.wasDecrementImpressionsCalled).toEventually(beTrue())
                }

                it("will dispatch all campaigns") {
                    permissionClient.shouldGrantPermission = true
                    TestHelpers.MockResponse.withGeneratedCampaigns(count: 10, test: false, delay: 10).data.forEach {
                        dispatcher.addToQueue(campaign: $0)
                    }
                    dispatcher.dispatchAllIfNeeded()
                    expect(router.displayedCampaignsCount).toEventually(equal(10))
                }
            }
        }
    }
}

private class RouterMock: RouterType {
    var accessibilityCompatibleDisplay = false
    var lastDisplayedCampaign: Campaign?
    var displayedCampaignsCount = 0

    func displayCampaign(_ campaign: Campaign, completion: @escaping () -> Void) {
        lastDisplayedCampaign = campaign
        displayedCampaignsCount += 1
        completion()
    }
}

private class PermissionClientMock: PermissionClientType {
    var shouldGrantPermission = false

    func checkPermission(withCampaign campaign: CampaignData) -> Bool {
        return shouldGrantPermission
    }
}

private class CampaignRepositoryMock: CampaignRepositoryType {
    var list: [Campaign] = []
    var lastSyncInMilliseconds: Int64?
    var resourcesToLock: [LockableResource] = []

    var wasDecrementImpressionsCalled = false

    func decrementImpressionsLeftInCampaign(_ campaign: Campaign) -> Campaign? {
        wasDecrementImpressionsCalled = true
        return Campaign.updatedCampaign(campaign, withImpressionLeft: campaign.impressionsLeft - 1)
    }

    func syncWith(list: [Campaign], timestampMilliseconds: Int64) { }
    func optOutCampaign(_ campaign: Campaign) -> Campaign? { return nil }
}
