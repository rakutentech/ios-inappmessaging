import Foundation
import Quick
import Nimble
import UIKit

#if canImport(RSDKUtilsTestHelpers)
import class RSDKUtilsTestHelpers.URLSessionMock // SPM version
#else
import class RSDKUtils.URLSessionMock
#endif

@testable import RInAppMessaging

class ReadyCampaignDispatcherSpec: QuickSpec {

    override func spec() {
        describe("CampaignDispatcher") {
            var dispatcher: CampaignDispatcher!
            var permissionService: DisplayPermissionServiceMock!
            var campaignRepository: CampaignRepositoryMock!
            var delegate: Delegate!
            var router: RouterMock!
            var httpSession: URLSessionMock!
            var imageDetails: [String: ImageDetails]!
            var images: [UIImage?]!
            var result: [CarouselData]!
            var eventlogger: MockEventLoggerSendable!

            beforeEach {
                URLCache.shared.removeAllCachedResponses()
                permissionService = DisplayPermissionServiceMock()
                campaignRepository = CampaignRepositoryMock()
                router = RouterMock()
                delegate = Delegate()
                eventlogger = MockEventLoggerSendable()
                dispatcher = CampaignDispatcher(router: router,
                                                permissionService: permissionService,
                                                campaignRepository: campaignRepository,
                                                eventlogger: eventlogger)
                dispatcher.delegate = delegate

                URLSessionMock.startMockingURLSession()
                httpSession = URLSessionMock.mock(originalInstance: dispatcher.httpSession)

                // simulated success response for imageUrl
                httpSession.httpResponse = HTTPURLResponse(url: URL(string: "https://example.com/cat.jpg")!,
                                                           statusCode: 200,
                                                           httpVersion: nil,
                                                           headerFields: nil)
                httpSession.responseData = Data()
                httpSession.responseError = nil
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()
            }

            context("when the carousel image URL is invalid") {
                it("returns nil and does not cache the response") {
                    let invalidURL = "invalid-url"

                    dispatcher.fetchCarouselImage(for: invalidURL) { image in
                        expect(image).to(beNil())

                        let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: URL(string: invalidURL)!))
                        expect(cachedResponse).to(beNil())
                    }
                }
            }

            context("when the network request fails for carousel image fetch") {
                it("returns nil and does not cache the response") {
                    let failedURL = "https://example.com/invalid-image.jpg"
                    let url = URL(string: failedURL)!

                    httpSession.httpResponse = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)
                    httpSession.responseData = nil
                    httpSession.responseError = NSError(domain: "NetworkError", code: 404, userInfo: nil)

                    dispatcher.fetchCarouselImage(for: failedURL) { image in
                        expect(image).to(beNil())

                        let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url))
                        expect(cachedResponse).to(beNil())
                    }
                }
            }

            context("when a valid image URL is provided in the carousel data") {
                let validURL = "https://example.com/valid-image.jpg"
                let url = URL(string: validURL)!

                beforeEach {
                    let imageData = UIImage(named: "test-image", in: .unitTests, with: nil)!.pngData()!
                    httpSession.httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
                    httpSession.responseData = imageData
                }

                it("fetches and caches the image") {
                    dispatcher.fetchCarouselImage(for: validURL) { image in
                        expect(image).toNot(beNil())
                        expect(image?.pngData()).to(equal(httpSession.responseData))

                        let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url))
                        expect(cachedResponse).toNot(beNil())
                        expect(cachedResponse?.data).to(equal(httpSession.responseData))
                    }
                }

                it("returns the cached image for subsequent requests") {
                    // Fetch the image once to cache it
                    dispatcher.fetchCarouselImage(for: validURL) { _ in }

                    // Fetch the image again to verify it comes from the cache
                    dispatcher.fetchCarouselImage(for: validURL) { image in
                        expect(image).toNot(beNil())
                        let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url))
                        expect(cachedResponse).toNot(beNil())
                        expect(image?.pngData()).to(equal(cachedResponse?.data))
                    }
                }
            }

            context("when the carousel data has no image URLs") {

                it("returns an empty array") {
                    let carousel = Carousel(images: [:])

                    waitUntil { done in
                        dispatcher.fetchImagesArray(from: carousel) { images in
                            expect(images).to(beEmpty())
                            done()
                        }
                    }
                }
            }

            context("when the carousel data has invalid image URLs") {
                beforeEach {
                    httpSession.httpResponse = HTTPURLResponse(url: URL(string: "https://invalid-url.com")!,
                                                               statusCode: 404,
                                                               httpVersion: nil,
                                                               headerFields: nil)
                    httpSession.responseData = nil
                    httpSession.responseError = NSError(domain: NSURLErrorDomain, code: URLError.badURL.rawValue, userInfo: nil)
                }

                it("returns an array with nil values") {
                    let imageDetails: [String: ImageDetails] = [
                        "1": ImageDetails(imgUrl: "https://invalid-url.com", link: "", altText: "")
                    ]
                    let carousel = Carousel(images: imageDetails)
                    waitUntil { done in
                        dispatcher.fetchImagesArray(from: carousel) { images in
                            expect(images.count).to(equal(imageDetails.count))
                            expect(images).to(containElementSatisfying { $0 == nil })
                            done()
                        }
                    }
                }
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
                                    id: "test1", title: "[ctx] title", maxImpressions: 1, delay: 10000)
                                let secondCampaign = TestHelpers.generateCampaign(
                                    id: "test2", title: "title", maxImpressions: 1, delay: 10000)
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
                                let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title", test: true)
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

                            it("will not decrement impressions left value (cancelled display)") {
                                let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                                campaignRepository.list = [campaign]
                                dispatcher.addToQueue(campaignID: campaign.id)
                                dispatcher.dispatchAllIfNeeded()
                                expect(campaignRepository.decrementImpressionsCalls).toAfterTimeout(equal(0))
                            }
                        }
                    }

                    it("will display campaign when carousel data is defined") {
                        // swiftlint:disable line_length
                        let campaign =
                        TestHelpers.generateCampaign(id: "test",
                                                     title: "title",
                                                     type: .modal,
                                                     test: false,
                                                     hasImage: false,
                                                     customJson: CustomJson(carousel: Carousel(images: ["1": ImageDetails(imgUrl: "https://static.id.rakuten.co.jp/static/com/img/id/Rakuten_pc_20px@2x.png", link: "https://www.google.com", altText: "error loading image")])))
                        // swiftlint:enable line_length

                        campaignRepository.list = [campaign]
                        dispatcher.addToQueue(campaignID: campaign.id)
                        dispatcher.dispatchAllIfNeeded()
                        expect(router.lastDisplayedCampaign).toAfterTimeout(equal(campaign))
                    }

                    it("will display campaign when imageUrl is defined") {
                        let campaign = TestHelpers.generateCampaign(id: "test", title: "title", type: .modal, test: false, hasImage: true)
                        campaignRepository.list = [campaign]
                        dispatcher.addToQueue(campaignID: campaign.id)
                        dispatcher.dispatchAllIfNeeded()
                        expect(router.lastDisplayedCampaign).toAfterTimeout(equal(campaign))
                    }

                    context("httpSession errors on loading imageUrl") {
                        beforeEach {
                            httpSession.httpResponse = HTTPURLResponse(url: URL(string: "https://example.com/cat.jpg")!,
                                                                       statusCode: 500,
                                                                       httpVersion: nil,
                                                                       headerFields: nil)
                            httpSession.responseError = NSError(domain: "campaign.error.test", code: 1, userInfo: nil)
                        }

                        it("won't display campaign when imageUrl is defined") {
                            let campaign = TestHelpers.generateCampaign(id: "test", title: "title", type: .modal, test: false, hasImage: true)
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
                            id: "test1", maxImpressions: 1, delay: 10000, test: false)
                        let secondCampaign = TestHelpers.generateCampaign(
                            id: "test2", maxImpressions: 1, delay: 10000, test: true)
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

                    func dispatchWithDisplayTime(_ displayTime: TimeInterval) {
                        router.displayTime = displayTime
                        dispatcher.dispatchAllIfNeeded()
                    }

                    beforeEach {
                        campaignRepository.list = testCampaigns
                        dispatcher.addToQueue(campaignID: testCampaigns[0].id)
                        dispatcher.addToQueue(campaignID: testCampaigns[1].id)
                    }

                    it("will not change dispatching mode to false if campaign is displayed") {
                        dispatchWithDisplayTime(2.0)
                        expect(dispatcher.isDispatching).toEventually(beTrue())
                        expect(router.wasDisplayCampaignCalled).toEventually(beTrue())
                        dispatcher.resetQueue()
                        expect(dispatcher.isDispatching).toAfterTimeout(beTrue())
                    }

                    it("will stop dispatching if campaign is not displayed") {
                        dispatchWithDisplayTime(1.0)
                        expect(dispatcher.isDispatching).toEventually(beTrue())
                        expect(dispatcher.scheduledTask).toEventuallyNot(beNil(), timeout: .seconds(2)) // wait for close
                        dispatcher.resetQueue()
                        expect(dispatcher.isDispatching).toEventually(beFalse())
                    }

                    it("will remove all queued campaigns") {
                        dispatchWithDisplayTime(0.5)
                        expect(dispatcher.isDispatching).toEventually(beTrue()) // wait
                        dispatcher.resetQueue()
                        dispatcher.addToQueue(campaignID: testCampaigns[2].id)
                        dispatcher.dispatchAllIfNeeded()
                        expect(router.lastDisplayedCampaign).toEventually(equal(testCampaigns[2]), timeout: .seconds(3))
                        expect(router.displayedCampaignsCount).to(equal(2))
                    }

                    it("will stop scheduled dispatch") {
                        dispatchWithDisplayTime(0.5)
                        expect(dispatcher.scheduledTask).toEventuallyNot(beNil()) // wait
                        dispatcher.resetQueue()
                        expect(dispatcher.scheduledTask?.isCancelled).toEventually(beTrue())
                        expect(dispatcher.queuedCampaignIDs).to(beEmpty())
                        expect(router.displayedCampaignsCount).to(equal(1))
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
                    expect(campaignRepository.decrementImpressionsCalls).toEventually(equal(1))
                }

                it("will not decrement or increment impressions left value if contexts were rejected") {
                    delegate.shouldShowCampaign = false
                    let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                    campaignRepository.list = [campaign]
                    dispatcher.addToQueue(campaignID: campaign.id)
                    dispatcher.dispatchAllIfNeeded()
                    expect(campaignRepository.decrementImpressionsCalls).toAfterTimeout(equal(0))
                    expect(campaignRepository.incrementImpressionsCalls).to(equal(0))
                }

                it("will decrement impressions left value if contexts were approved") {
                    delegate.shouldShowCampaign = true
                    let campaign = TestHelpers.generateCampaign(id: "test", title: "[ctx] title")
                    campaignRepository.list = [campaign]
                    dispatcher.addToQueue(campaignID: campaign.id)
                    dispatcher.dispatchAllIfNeeded()
                    expect(campaignRepository.decrementImpressionsCalls).toEventually(equal(1))
                    expect(campaignRepository.incrementImpressionsCalls).to(equal(0))
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
                    expect(dispatcher.isDispatching).toEventually(beTrue())
                    expect(router.displayedCampaignsCount).toEventually(equal(1))
                    expect(dispatcher.isDispatching).toEventually(beFalse())
                }
            }

            context("when data and images are valid") {
                beforeEach {
                    imageDetails = [
                        "1": ImageDetails(imgUrl: "https://www.sample.com/image1.png", link: "https://example.com/1", altText: "Alt 1"),
                        "2": ImageDetails(imgUrl: "https://www.sample.com/image2.png", link: "https://example.com/2", altText: "Alt 2"),
                        "3": ImageDetails(imgUrl: "https://www.sample.com/image3.png", link: "https://example.com/3", altText: "Alt 3")
                    ]
                    images = [UIImage(named: "test-image", in: .unitTests, with: nil),
                              UIImage(named: "test-image", in: .unitTests, with: nil),
                              UIImage(named: "test-image", in: .unitTests, with: nil)
                    ]
                    result = dispatcher.createCarouselDataList(from: imageDetails, using: images)
                }

                it("should return a list of correct CarouselData objects") {
                    expect(result.count).to(equal(3))

                    expect(result[0].altText).to(equal("Alt 1"))
                    expect(result[0].link).to(equal("https://example.com/1"))
                    expect(result[0].image).toNot(beNil())

                    expect(result[1].altText).to(equal("Alt 2"))
                    expect(result[1].link).to(equal("https://example.com/2"))
                    expect(result[1].image).toNot(beNil())

                    expect(result[2].altText).to(equal("Alt 3"))
                    expect(result[2].link).to(equal("https://example.com/3"))
                    expect(result[2].image).toNot(beNil())
                }
            }

            context("when images have nil entries") {
                beforeEach {
                    imageDetails = [
                        "1": ImageDetails(imgUrl: "https://www.sample.com/image1.png", link: "https://example.com/1", altText: "Alt 1"),
                        "2": ImageDetails(imgUrl: "https://www.sample.com/image2.png", link: "https://example.com/2", altText: "Alt 2"),
                        "3": ImageDetails(imgUrl: "https://www.sample.com/image3.png", link: "https://example.com/3", altText: "Alt 3")
                    ]
                    images = [UIImage(named: "test-image", in: .unitTests, with: nil), nil]
                    result = dispatcher.createCarouselDataList(from: imageDetails, using: images)
                }

                it("should handle nil images and still create data objects") {
                    expect(result.count).to(equal(2))

                    expect(result[0].image).toNot(beNil())
                    expect(result[0].altText).to(equal("Alt 1"))
                    expect(result[1].image).to(beNil())
                    expect(result[1].altText).to(equal("Alt 2"))
                }
            }

            context("when images count is fewer than data entries") {
                beforeEach {
                    imageDetails = [
                        "1": ImageDetails(imgUrl: "https://www.sample.com/image1.png", link: "https://example.com/1", altText: "Alt 1"),
                        "2": ImageDetails(imgUrl: "https://www.sample.com/image2.png", link: "https://example.com/2", altText: "Alt 2"),
                        "3": ImageDetails(imgUrl: "https://www.sample.com/image3.png", link: "https://example.com/3", altText: "Alt 3")
                    ]
                    images = [UIImage(named: "test-image", in: .unitTests, with: nil),
                              UIImage(named: "test-image", in: .unitTests, with: nil)]

                    result = dispatcher.createCarouselDataList(from: imageDetails, using: images)
                }

                it("should only include entries with matching images") {
                    expect(result.count).to(equal(2))

                    expect(result[0].altText).to(equal("Alt 1"))
                    expect(result[0].image).toNot(beNil())

                    expect(result[1].altText).to(equal("Alt 2"))
                    expect(result[1].image).toNot(beNil())
                }
            }

            context("when data is empty") {
                beforeEach {
                    imageDetails = [:]
                    images = [UIImage(named: "test-image", in: .unitTests, with: nil),
                              UIImage(named: "test-image", in: .unitTests, with: nil)]
                    result = dispatcher.createCarouselDataList(from: imageDetails, using: images)
                }

                it("should return an empty list") {
                    expect(result).to(beEmpty())
                }
            }

            context("when images are empty") {
                beforeEach {
                    imageDetails = [
                        "1": ImageDetails(imgUrl: "https://www.sample.com/image1.png", link: "https://example.com/1", altText: "Alt 1"),
                        "2": ImageDetails(imgUrl: "https://www.sample.com/image2.png", link: "https://example.com/2", altText: "Alt 2"),
                        "3": ImageDetails(imgUrl: "https://www.sample.com/image3.png", link: "https://example.com/3", altText: "Alt 3")
                    ]
                    images = []

                    result = dispatcher.createCarouselDataList(from: imageDetails, using: images)
                }

                it("should return an empty list") {
                    expect(result).to(beEmpty())
                }
            }

            context("when all images are nil") {
                beforeEach {
                    imageDetails = [
                        "1": ImageDetails(imgUrl: "https://www.sample.com/image1.png", link: "https://example.com/1", altText: "Alt 1"),
                        "2": ImageDetails(imgUrl: "https://www.sample.com/image2.png", link: "https://example.com/2", altText: "Alt 2")
                    ]
                    images = [nil, nil]
                    result = dispatcher.createCarouselDataList(from: imageDetails, using: images)
                }

                it("should still create data objects with nil images") {
                    expect(result.count).to(equal(2))

                    expect(result[0].image).to(beNil())
                    expect(result[0].altText).to(equal("Alt 1"))

                    expect(result[1].image).to(beNil())
                    expect(result[1].altText).to(equal("Alt 2"))
                }
            }

            context("when keys are unsorted") {
                beforeEach {
                    imageDetails = [
                        "3": ImageDetails(imgUrl: "https://www.sample.com/image3.png", link: "https://example.com/3", altText: "Alt 3"),
                        "1": ImageDetails(imgUrl: "https://www.sample.com/image1.png", link: "https://example.com/1", altText: "Alt 1"),
                        "2": ImageDetails(imgUrl: "https://www.sample.com/image2.png", link: "https://example.com/2", altText: "Alt 2")
                    ]
                    images = [UIImage(named: "test-image", in: .unitTests, with: nil),
                              UIImage(named: "test-image", in: .unitTests, with: nil),
                              UIImage(named: "test-image", in: .unitTests, with: nil)]
                    result = dispatcher.createCarouselDataList(from: imageDetails, using: images)
                }

                it("should return sorted CarouselData list based on keys") {
                    expect(result.count).to(equal(3))

                    expect(result[0].altText).to(equal("Alt 1"))
                    expect(result[1].altText).to(equal("Alt 2"))
                    expect(result[2].altText).to(equal("Alt 3"))
                }
            }
        }
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
