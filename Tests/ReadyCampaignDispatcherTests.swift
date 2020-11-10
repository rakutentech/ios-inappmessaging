import Quick
import Nimble
@testable import RInAppMessaging

class ReadyCampaignDispatcherTests: QuickSpec {

    override func spec() {
        describe("CampaignDispatcher") {
            var dispatcher: CampaignDispatcher!
            var permissionService: PermissionServiceMock!
            var campaignRepository: CampaignRepositoryMock!
            var delegate: Delegate!
            var router: RouterMock!

            beforeEach {
                permissionService = PermissionServiceMock()
                campaignRepository = CampaignRepositoryMock()
                router = RouterMock()
                delegate = Delegate()
                dispatcher = CampaignDispatcher(router: router,
                                                permissionService: permissionService,
                                                campaignRepository: campaignRepository)
                dispatcher.delegate = delegate
            }

            context("before dispatching") {

                it("won't start dispatching while adding to the queue") {
                    permissionService.shouldGrantPermission = true
                    let testCampaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 3, test: false, delay: 0).data
                    testCampaigns.forEach {
                        dispatcher.addToQueue(campaign: $0)
                    }
                    expect(router.lastDisplayedCampaign).toAfterTimeout(beNil(), timeout: 0.1)
                }
            }

            context("while dispatching") {

                context("when display permission is granted") {
                    beforeEach {
                        permissionService.shouldGrantPermission = true
                    }

                    context("and delegate is nil") {
                        beforeEach {
                            delegate = nil
                            dispatcher.delegate = nil
                        }

                        it("will display newly added campaigns") {
                            let testCampaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 3, test: false, delay: 500).data
                            let firstCampaign = testCampaigns[0]
                            let secondCampaign = testCampaigns[1]
                            let thirdCampaign = testCampaigns[2]
                            dispatcher.addToQueue(campaign: firstCampaign)
                            dispatcher.addToQueue(campaign: secondCampaign)
                            dispatcher.dispatchAllIfNeeded()
                            dispatcher.addToQueue(campaign: thirdCampaign)
                            expect(router.lastDisplayedCampaign).toEventually(equal(thirdCampaign), timeout: .seconds(2))
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
                            expect(router.lastDisplayedCampaign).toAfterTimeout(equal(firstCampaign))
                        }
                    }

                    context("delegate is not nil") {

                        it("will call delegate if contexts are present") {
                            let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                            dispatcher.addToQueue(campaign: campaign)
                            dispatcher.dispatchAllIfNeeded()
                            expect(delegate.wasShouldShowCalled).toEventually(beTrue())
                        }

                        it("will not call delegate if contexts are not present") {
                            let campaign = TestHelpers.generateCampaign(id: "test", title: "title")
                            dispatcher.addToQueue(campaign: campaign)
                            dispatcher.dispatchAllIfNeeded()
                            expect(delegate.wasShouldShowCalled).toAfterTimeout(beFalse())
                        }

                        it("will display campaign normally if contexts are not present") {
                            let campaign = TestHelpers.generateCampaign(id: "test", title: "title")
                            dispatcher.addToQueue(campaign: campaign)
                            dispatcher.dispatchAllIfNeeded()
                            expect(router.lastDisplayedCampaign).toEventually(equal(campaign))
                        }

                        context("and contexts are approved") {
                            beforeEach {
                                delegate.shouldShowCampaign = true
                            }

                            it("will display newly added campaigns") {
                                let firstCampaign = TestHelpers.generateCampaign(id: "test", title: "[ctx1] title")
                                let secondCampaign = TestHelpers.generateCampaign(id: "test", title: "[ctx2] title")
                                dispatcher.addToQueue(campaign: firstCampaign)
                                dispatcher.addToQueue(campaign: secondCampaign)
                                dispatcher.dispatchAllIfNeeded()
                                expect(router.lastDisplayedCampaign).toEventually(equal(firstCampaign))
                                expect(router.lastDisplayedCampaign).toEventually(equal(secondCampaign))
                            }
                        }

                        context("and contexts are not approved") {
                            beforeEach {
                                delegate.shouldShowCampaign = false
                            }

                            it("will dispatch next campaign immediately") {
                                let firstCampaign = TestHelpers.generateCampaign(
                                    id: "test1", test: false, delay: 10000, maxImpressions: 1,
                                    title: "[ctx] title")
                                let secondCampaign = TestHelpers.generateCampaign(
                                    id: "test2", test: false, delay: 10000, maxImpressions: 1,
                                    title: "title")
                                dispatcher.addToQueue(campaign: firstCampaign)
                                dispatcher.addToQueue(campaign: secondCampaign)
                                dispatcher.dispatchAllIfNeeded()
                                expect(router.lastDisplayedCampaign).toEventually(equal(secondCampaign), timeout: .milliseconds(500))
                            }

                            it("will not display campaigns with context") {
                                let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                                dispatcher.addToQueue(campaign: campaign)
                                dispatcher.dispatchAllIfNeeded()
                                expect(router.lastDisplayedCampaign).toAfterTimeout(beNil())
                            }

                            it("will always dispatch test campaigns") {
                                let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title", isTest: true)
                                dispatcher.addToQueue(campaign: campaign)
                                dispatcher.dispatchAllIfNeeded()
                                expect(router.lastDisplayedCampaign).toEventually(equal(campaign))
                            }

                            it("will perform ping if flag in the response is true") {
                                permissionService.shouldPerformPing = true
                                let testCampaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                                dispatcher.addToQueue(campaign: testCampaign)
                                dispatcher.dispatchAllIfNeeded()
                                expect(delegate.wasPingCalled).toEventually(beTrue())
                            }
                        }
                    }
                }

                context("when display permission is denied") {
                    beforeEach {
                        permissionService.shouldGrantPermission = false
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

                    it("will dispatch next campaign immediately") {
                        let firstCampaign = TestHelpers.generateCampaign(
                            id: "test1", test: false, delay: 10000, maxImpressions: 1)
                        let secondCampaign = TestHelpers.generateCampaign(
                            id: "test2", test: true, delay: 10000, maxImpressions: 1)
                        dispatcher.addToQueue(campaign: firstCampaign)
                        dispatcher.addToQueue(campaign: secondCampaign)
                        dispatcher.dispatchAllIfNeeded()
                        expect(router.lastDisplayedCampaign).toEventually(equal(secondCampaign), timeout: .milliseconds(500))
                    }

                    it("won't dispatch non-test campaigns") {
                        let campaign = TestHelpers.MockResponse.withGeneratedCampaigns(count: 1, test: false, delay: 0).data[0]
                        dispatcher.addToQueue(campaign: campaign)
                        dispatcher.dispatchAllIfNeeded()
                        expect(router.lastDisplayedCampaign).toAfterTimeout(beNil(), timeout: 0.1)
                    }

                    it("will perform ping if flag in the response is true") {
                        permissionService.shouldPerformPing = true
                        let testCampaign = TestHelpers.generateCampaign(id: "test")
                        dispatcher.addToQueue(campaign: testCampaign)
                        dispatcher.dispatchAllIfNeeded()
                        expect(delegate.wasPingCalled).toEventually(beTrue())
                    }

                    it("won't call shouldShowCampaignMessage delegate method for non-test campaigns") {
                        let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                        dispatcher.addToQueue(campaign: campaign)
                        dispatcher.dispatchAllIfNeeded()
                        expect(delegate.wasShouldShowCalled).toAfterTimeout(beFalse())
                    }

                    it("won't call shouldShowCampaignMessage delegate method for test campaigns") {
                        let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                        dispatcher.addToQueue(campaign: campaign)
                        dispatcher.dispatchAllIfNeeded()
                        expect(delegate.wasShouldShowCalled).toAfterTimeout(beFalse())
                    }
                }
            }

            context("after dispatching") {

                it("will decrement impressions left in campaign") {
                    permissionService.shouldGrantPermission = true
                    let campaign = TestHelpers.MockResponse.withGeneratedCampaigns(count: 1, test: false, delay: 0).data[0]
                    dispatcher.addToQueue(campaign: campaign)
                    dispatcher.dispatchAllIfNeeded()
                    expect(campaignRepository.wasDecrementImpressionsCalled).toEventually(beTrue())
                }

                it("will dispatch remaining campaigns") {
                    permissionService.shouldGrantPermission = true
                    TestHelpers.MockResponse.withGeneratedCampaigns(count: 10, test: false, delay: 10).data.forEach {
                        dispatcher.addToQueue(campaign: $0)
                    }
                    dispatcher.dispatchAllIfNeeded()
                    expect(router.displayedCampaignsCount).toEventually(equal(10))
                }

                it("will schedule next dispatch after a delay defined in campaign data") {
                    permissionService.shouldGrantPermission = true
                    TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 1000).data.forEach {
                        dispatcher.addToQueue(campaign: $0)
                    }
                    dispatcher.dispatchAllIfNeeded()
                    expect(router.displayedCampaignsCount).toEventually(equal(1))
                    expect(router.displayedCampaignsCount).toAfterTimeout(equal(1), timeout: 0.5)
                    expect(router.displayedCampaignsCount).toAfterTimeout(equal(2), timeout: 0.5)
                }

                it("won't schedule next dispatch if there are no queued campaigns") {
                    permissionService.shouldGrantPermission = true
                    let campaign = TestHelpers.MockResponse.withGeneratedCampaigns(count: 1, test: false, delay: 0).data[0]
                    dispatcher.addToQueue(campaign: campaign)
                    dispatcher.dispatchAllIfNeeded()
                    expect(router.displayedCampaignsCount).toEventually(equal(1))
                    expect(dispatcher.isDispatching).to(beFalse())
                }

                it("won't schedule next dispatch if there are no queued campaigns") {
                    permissionService.shouldGrantPermission = true
                    let campaign = TestHelpers.MockResponse.withGeneratedCampaigns(count: 1, test: false, delay: 0).data[0]
                    dispatcher.addToQueue(campaign: campaign)
                    dispatcher.dispatchAllIfNeeded()
                    expect(router.displayedCampaignsCount).toEventually(equal(1))
                    expect(dispatcher.isDispatching).to(beFalse())
                }
            }
        }
    }
}

private class RouterMock: RouterType {
    var accessibilityCompatibleDisplay = false
    var lastDisplayedCampaign: Campaign?
    var displayedCampaignsCount = 0

    func displayCampaign(_ campaign: Campaign,
                         confirmation: @escaping @autoclosure () -> Bool,
                         completion: @escaping (_ cancelled: Bool) -> Void) {
        guard confirmation() else {
            completion(true)
            return
        }
        lastDisplayedCampaign = campaign
        displayedCampaignsCount += 1
        completion(false)
    }
}

private class PermissionServiceMock: DisplayPermissionServiceType {
    var shouldGrantPermission = false
    var shouldPerformPing = false

    func checkPermission(forCampaign campaign: CampaignData) -> DisplayPermissionResponse {
        return DisplayPermissionResponse(display: shouldGrantPermission,
                                         performPing: shouldPerformPing)
    }
}

private class Delegate: CampaignDispatcherDelegate {
    var wasPingCalled = false
    var wasShouldShowCalled = false
    var shouldShowCampaign = true

    func performPing() {
        wasPingCalled = true
    }

    func shouldShowCampaignMessage(title: String, contexts: [String]) -> Bool {
        wasShouldShowCalled = true
        return shouldShowCampaign
    }
}
