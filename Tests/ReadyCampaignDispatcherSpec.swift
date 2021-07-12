import Quick
import Nimble
@testable import RInAppMessaging

class ReadyCampaignDispatcherSpec: QuickSpec {

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

                dispatcher.httpSession = URLSessionMock.mock(originalInstance: .shared)
                // swiftlint:disable:next force_cast
                let httpSession = dispatcher.httpSession as! URLSessionMock

                // simulated data response for imageUrl
                httpSession.httpResponse = HTTPURLResponse(url: URL(string: "https://example.com/cat.jpg")!,
                                                           statusCode: 200,
                                                           httpVersion: nil,
                                                           headerFields: nil)
                httpSession.responseData = Data()
                httpSession.responseError = nil
            }

            context("before dispatching") {

                it("won't start dispatching while adding to the queue") {
                    permissionService.shouldGrantPermission = true
                    let testCampaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 3, test: false, delay: 0).data
                    testCampaigns.forEach {
                        dispatcher.addToQueue(campaignID: $0.id)
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
                            campaignRepository.list = testCampaigns
                            let firstCampaign = testCampaigns[0]
                            let secondCampaign = testCampaigns[1]
                            let thirdCampaign = testCampaigns[2]
                            dispatcher.addToQueue(campaignID: firstCampaign.id)
                            dispatcher.addToQueue(campaignID: secondCampaign.id)
                            dispatcher.dispatchAllIfNeeded()
                            dispatcher.addToQueue(campaignID: thirdCampaign.id)
                            expect(router.lastDisplayedCampaign).toEventually(equal(thirdCampaign), timeout: .seconds(2))
                        }

                        it("won't start another dispatch procedure if one has already started") {
                            let testCampaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 8000).data
                            campaignRepository.list = testCampaigns
                            let firstCampaign = testCampaigns[0]
                            let secondCampaign = testCampaigns[1]
                            dispatcher.addToQueue(campaignID: firstCampaign.id)
                            dispatcher.addToQueue(campaignID: secondCampaign.id)
                            dispatcher.dispatchAllIfNeeded()
                            expect(router.lastDisplayedCampaign).toEventually(equal(firstCampaign))
                            dispatcher.dispatchAllIfNeeded()
                            expect(router.lastDisplayedCampaign).toAfterTimeout(equal(firstCampaign))
                        }
                    }

                    context("delegate is not nil") {

                        it("will call delegate if contexts are present") {
                            let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                            campaignRepository.list = [campaign]
                            dispatcher.addToQueue(campaignID: campaign.id)
                            dispatcher.dispatchAllIfNeeded()
                            expect(delegate.wasShouldShowCalled).toEventually(beTrue())
                        }

                        it("will not call delegate if contexts are not present") {
                            let campaign = TestHelpers.generateCampaign(id: "test", title: "title")
                            campaignRepository.list = [campaign]
                            dispatcher.addToQueue(campaignID: campaign.id)
                            dispatcher.dispatchAllIfNeeded()
                            expect(delegate.wasShouldShowCalled).toAfterTimeout(beFalse())
                        }

                        it("will display campaign normally if contexts are not present") {
                            let campaign = TestHelpers.generateCampaign(id: "test", title: "title")
                            campaignRepository.list = [campaign]
                            dispatcher.addToQueue(campaignID: campaign.id)
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
                                campaignRepository.list = [firstCampaign, secondCampaign]
                                dispatcher.addToQueue(campaignID: firstCampaign.id)
                                dispatcher.addToQueue(campaignID: secondCampaign.id)
                                dispatcher.dispatchAllIfNeeded()
                                expect(router.lastDisplayedCampaign).toEventually(equal(firstCampaign))
                                expect(router.lastDisplayedCampaign).toEventually(equal(secondCampaign))
                            }

                            it("will not restore impressions left value") {
                                let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                                campaignRepository.list = [campaign]
                                dispatcher.addToQueue(campaignID: campaign.id)
                                dispatcher.dispatchAllIfNeeded()
                                expect(campaignRepository.incrementImpressionsCalls).toAfterTimeout(equal(0))
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
                                campaignRepository.list = [firstCampaign, secondCampaign]
                                dispatcher.addToQueue(campaignID: firstCampaign.id)
                                dispatcher.addToQueue(campaignID: secondCampaign.id)
                                dispatcher.dispatchAllIfNeeded()
                                expect(router.lastDisplayedCampaign).toEventually(equal(secondCampaign), timeout: .milliseconds(500))
                            }

                            it("will not display campaigns with context") {
                                let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                                campaignRepository.list = [campaign]
                                dispatcher.addToQueue(campaignID: campaign.id)
                                dispatcher.dispatchAllIfNeeded()
                                expect(router.lastDisplayedCampaign).toAfterTimeout(beNil())
                            }

                            it("will always dispatch test campaigns") {
                                let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title", isTest: true)
                                campaignRepository.list = [campaign]
                                dispatcher.addToQueue(campaignID: campaign.id)
                                dispatcher.dispatchAllIfNeeded()
                                expect(router.lastDisplayedCampaign).toEventually(equal(campaign))
                            }

                            it("will perform ping if flag in the response is true") {
                                permissionService.shouldPerformPing = true
                                let testCampaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                                campaignRepository.list = [testCampaign]
                                dispatcher.addToQueue(campaignID: testCampaign.id)
                                dispatcher.dispatchAllIfNeeded()
                                expect(delegate.wasPingCalled).toEventually(beTrue())
                            }

                            it("will restore impressions left value (cancelled display)") {
                                let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                                campaignRepository.list = [campaign]
                                dispatcher.addToQueue(campaignID: campaign.id)
                                dispatcher.dispatchAllIfNeeded()
                                expect(campaignRepository.incrementImpressionsCalls).toAfterTimeout(equal(1))
                            }
                        }
                    }

                    it("will display campaign when imageUrl is defined") {
                        let campaign = TestHelpers.generateCampaign(id: "test", title: "title", type: .modal, isTest: false, hasImage: true)
                        campaignRepository.list = [campaign]
                        dispatcher.addToQueue(campaignID: campaign.id)
                        dispatcher.dispatchAllIfNeeded()
                        expect(router.lastDisplayedCampaign).toAfterTimeout(equal(campaign))
                    }

                    context("httpSession errors on loading imageUrl") {
                        beforeEach {
                            // swiftlint:disable:next force_cast
                            let httpSession = dispatcher.httpSession as! URLSessionMock
                            httpSession.httpResponse = HTTPURLResponse(url: URL(string: "https://example.com/cat.jpg")!,
                                                                       statusCode: 500,
                                                                       httpVersion: nil,
                                                                       headerFields: nil)
                            httpSession.responseError = NSError(domain: "campaign.error.test", code: 1, userInfo: nil)
                        }

                        it("won't display campaign when imageUrl is defined") {
                            let campaign = TestHelpers.generateCampaign(id: "test", title: "title", type: .modal, isTest: false, hasImage: true)
                            campaignRepository.list = [campaign]
                            dispatcher.addToQueue(campaignID: campaign.id)
                            dispatcher.dispatchAllIfNeeded()
                            expect(router.lastDisplayedCampaign).toAfterTimeout(beNil())
                        }
                    }
                }

                context("when display permission is denied") {
                    beforeEach {
                        permissionService.shouldGrantPermission = false
                    }

                    it("will always dispatch test campaigns") {
                        let testCampaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: true, delay: 500).data
                        campaignRepository.list = testCampaigns
                        let firstCampaign = testCampaigns[0]
                        let secondCampaign = testCampaigns[1]
                        dispatcher.addToQueue(campaignID: firstCampaign.id)
                        dispatcher.addToQueue(campaignID: secondCampaign.id)
                        dispatcher.dispatchAllIfNeeded()
                        expect(router.lastDisplayedCampaign).toEventually(equal(firstCampaign))
                        expect(router.lastDisplayedCampaign).toEventually(equal(secondCampaign))
                    }

                    it("will dispatch next campaign immediately") {
                        let firstCampaign = TestHelpers.generateCampaign(
                            id: "test1", test: false, delay: 10000, maxImpressions: 1)
                        let secondCampaign = TestHelpers.generateCampaign(
                            id: "test2", test: true, delay: 10000, maxImpressions: 1)
                        campaignRepository.list = [firstCampaign, secondCampaign]
                        dispatcher.addToQueue(campaignID: firstCampaign.id)
                        dispatcher.addToQueue(campaignID: secondCampaign.id)
                        dispatcher.dispatchAllIfNeeded()
                        expect(router.lastDisplayedCampaign).toEventually(equal(secondCampaign), timeout: .milliseconds(500))
                    }

                    it("won't dispatch non-test campaigns") {
                        let campaign = TestHelpers.MockResponse.withGeneratedCampaigns(count: 1, test: false, delay: 0).data[0]
                        dispatcher.addToQueue(campaignID: campaign.id)
                        dispatcher.dispatchAllIfNeeded()
                        expect(router.lastDisplayedCampaign).toAfterTimeout(beNil(), timeout: 0.1)
                    }

                    it("will perform ping if flag in the response is true") {
                        permissionService.shouldPerformPing = true
                        let testCampaign = TestHelpers.generateCampaign(id: "test")
                        campaignRepository.list = [testCampaign]
                        dispatcher.addToQueue(campaignID: testCampaign.id)
                        dispatcher.dispatchAllIfNeeded()
                        expect(delegate.wasPingCalled).toEventually(beTrue())
                    }

                    it("won't call shouldShowCampaignMessage delegate method for non-test campaigns") {
                        let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                        dispatcher.addToQueue(campaignID: campaign.id)
                        dispatcher.dispatchAllIfNeeded()
                        expect(delegate.wasShouldShowCalled).toAfterTimeout(beFalse())
                    }

                    it("won't call shouldShowCampaignMessage delegate method for test campaigns") {
                        let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                        dispatcher.addToQueue(campaignID: campaign.id)
                        dispatcher.dispatchAllIfNeeded()
                        expect(delegate.wasShouldShowCalled).toAfterTimeout(beFalse())
                    }
                }

                context("and resetQueue is called") {

                    let testCampaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 3, test: true, delay: 1000).data

                    beforeEach {
                        campaignRepository.list = testCampaigns
                        dispatcher.addToQueue(campaignID: testCampaigns[0].id)
                        dispatcher.addToQueue(campaignID: testCampaigns[1].id)
                        dispatcher.dispatchAllIfNeeded()
                    }

                    it("will not stop dispatching if campaign is displayed") {
                        router.displayTime = 2.0
                        expect(dispatcher.isDispatching).toEventually(beTrue())
                        expect(dispatcher.scheduledTask).toEventually(beNil()) // wait
                        dispatcher.resetQueue()
                        expect(dispatcher.isDispatching).toAfterTimeout(beTrue())
                    }

                    it("will stop dispatching if campaign is not displayed") {
                        expect(dispatcher.isDispatching).toEventually(beTrue())
                        expect(dispatcher.scheduledTask).toEventuallyNot(beNil()) // wait
                        dispatcher.resetQueue()
                        expect(dispatcher.isDispatching).toEventually(beFalse())
                    }

                    it("will remove all queued campaigns") {
                        expect(dispatcher.isDispatching).toEventually(beTrue()) // wait
                        dispatcher.resetQueue()
                        dispatcher.addToQueue(campaignID: testCampaigns[2].id)
                        dispatcher.dispatchAllIfNeeded()
                        expect(router.lastDisplayedCampaign).toEventually(equal(testCampaigns[2]), timeout: .seconds(2))
                        expect(router.displayedCampaignsCount).to(equal(2))
                    }

                    it("will stop scheduled dispatch") {
                        expect(dispatcher.scheduledTask).toEventuallyNot(beNil()) // wait
                        dispatcher.resetQueue()
                        expect(dispatcher.scheduledTask?.isCancelled).toEventually(beTrue())
                        expect(router.displayedCampaignsCount).toAfterTimeout(equal(1), timeout: 2)
                    }
                }
            }

            context("after dispatching") {
                beforeEach {
                    permissionService.shouldGrantPermission = true
                }

                it("will decrement impressions left in campaign") {
                    let campaign = TestHelpers.generateCampaign(id: "test")
                    campaignRepository.list = [campaign]
                    dispatcher.addToQueue(campaignID: campaign.id)
                    dispatcher.dispatchAllIfNeeded()
                    expect(campaignRepository.decrementImpressionsCalls).toAfterTimeout(equal(1))
                }

                it("will restore impressions left value if contexts were rejected") {
                    delegate.shouldShowCampaign = false
                    let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                    campaignRepository.list = [campaign]
                    dispatcher.addToQueue(campaignID: campaign.id)
                    dispatcher.dispatchAllIfNeeded()
                    expect(campaignRepository.incrementImpressionsCalls).toAfterTimeout(equal(1))
                }

                it("will not increment impressions left value if contexts were approved") {
                    delegate.shouldShowCampaign = true
                    let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                    campaignRepository.list = [campaign]
                    dispatcher.addToQueue(campaignID: campaign.id)
                    dispatcher.dispatchAllIfNeeded()
                    expect(campaignRepository.incrementImpressionsCalls).toAfterTimeout(equal(0))
                }

                it("will dispatch remaining campaigns") {
                    TestHelpers.MockResponse.withGeneratedCampaigns(count: 10, test: false, delay: 10).data.forEach {
                        campaignRepository.list.append($0)
                        dispatcher.addToQueue(campaignID: $0.id)
                    }
                    dispatcher.dispatchAllIfNeeded()
                    expect(router.displayedCampaignsCount).toEventually(equal(10), timeout: .seconds(2))
                }

                it("will schedule next dispatch after a delay defined in campaign data") {
                    TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 1000).data.forEach {
                        campaignRepository.list.append($0)
                        dispatcher.addToQueue(campaignID: $0.id)
                    }
                    dispatcher.dispatchAllIfNeeded()
                    expect(router.displayedCampaignsCount).toEventually(equal(1))
                    expect(router.displayedCampaignsCount).toAfterTimeout(equal(1), timeout: 0.5)
                    expect(router.displayedCampaignsCount).toAfterTimeout(equal(2), timeout: 1.0)
                }

                it("won't schedule next dispatch if there are no queued campaigns") {
                    let campaign = TestHelpers.MockResponse.withGeneratedCampaigns(count: 1, test: false, delay: 0).data[0]
                    campaignRepository.list = [campaign]
                    dispatcher.addToQueue(campaignID: campaign.id)
                    dispatcher.dispatchAllIfNeeded()
                    expect(router.displayedCampaignsCount).toEventually(equal(1))
                    expect(dispatcher.isDispatching).to(beFalse())
                }
            }
        }
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
