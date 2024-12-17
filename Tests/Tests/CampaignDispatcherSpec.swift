import Quick
import Nimble

@testable import RInAppMessaging

class CampaignDispatcherCarouselSpec: QuickSpec {
    override func spec() {
        var dispatcher: CampaignDispatcher!
        var mockRouter: RouterMock!
        var mockPermissionService: DisplayPermissionServiceMock!
        var mockCampaignRepository: CampaignRepositoryMock!
        var imageDetails: [String: ImageDetails]!
        var images: [UIImage?]!
        var result: [CarouselData]!

        beforeEach {
            mockRouter = RouterMock()
            mockPermissionService = DisplayPermissionServiceMock()
            mockCampaignRepository = CampaignRepositoryMock()

            dispatcher = CampaignDispatcher(
                router: mockRouter,
                permissionService: mockPermissionService,
                campaignRepository: mockCampaignRepository
            )
        }

        afterEach {
            MockURLProtocol.removeAllStubs()
        }

        describe("fetchImagesArray") {
            context("when the carousel has no images") {
                it("returns an empty array") {
                    let carousel = Carousel(images: nil)

                    waitUntil { done in
                        dispatcher.fetchImagesArray(from: carousel) { images in
                            expect(images).to(beEmpty())
                            done()
                        }
                    }
                }
            }

            context("when the carousel has valid image URLs") {
                it("fetches and returns an array of images") {
                    let imageDetails: [String: ImageDetails] = [
                        "1": ImageDetails(imgUrl: "https://static.id.rakuten.co.jp/static/com/img/id/Rakuten_pc_20px@2x.png", link: "", altText: ""),
                        "2": ImageDetails(imgUrl: "https://static.id.rakuten.co.jp/static/com/img/id/Rakuten_pc_20px@2x.png", link: "", altText: "")
                    ]
                    let carousel = Carousel(images: imageDetails)
                    MockURLProtocol.stubImageRequests()

                    waitUntil { done in
                        dispatcher.fetchImagesArray(from: carousel) { images in
                            expect(images.count).to(equal(imageDetails.count))
                            expect(images[0]).notTo(beNil())
                            expect(images[1]).notTo(beNil())
                            done()
                        }
                    }
                }
            }

            context("when the carousel contains invalid URLs") {
                it("returns an array with nil values for invalid images") {
                    let imageDetails: [String: ImageDetails] = [
                        "1": ImageDetails(imgUrl: "invalid-url", link: "", altText: ""),
                        "2": ImageDetails(imgUrl: nil, link: "", altText: "")
                    ]
                    let carousel = Carousel(images: imageDetails)

                    waitUntil { done in
                        dispatcher.fetchImagesArray(from: carousel) { images in
                            expect(images.count).to(equal(2))
                            expect(images[0]).to(beNil())
                            expect(images[1]).to(beNil())
                            done()
                        }
                    }
                }
            }
        }

        describe("fetchCarouselImage") {
            context("when the URL is valid and the image is cached") {
                it("returns the cached image") {

                    let urlString = "https://example.com/cached-image.png"
                    let sampleImageData = UIImage(named: "test-image", in: .unitTests, with: nil)?.pngData()
                    MockURLProtocol.stubCachedResponse(for: urlString, data: sampleImageData)

                    waitUntil { done in
                        dispatcher.fetchCarouselImage(for: urlString) { image in
                            expect(image).notTo(beNil())
                            expect(image?.pngData()).to(equal(sampleImageData))
                            done()
                        }
                    }

                    let urlString1 = "https://example.com/cached-image.png"
                    let sampleImageData1 = UIImage(named: "test-image", in: .unitTests, with: nil)?.pngData()
                    MockURLProtocol.stubCachedResponse(for: urlString, data: sampleImageData1)

                    let request = URLRequest(url: URL(string: urlString1)!)
                    let cachedResponse = URLCache.shared.cachedResponse(for: request)
                    expect(cachedResponse).notTo(beNil())
                    expect(cachedResponse?.data).to(equal(sampleImageData))
                }
            }

            context("when the URL is valid and the image is not cached") {
                it("downloads and caches the image") {
                    let urlString = "https://static.id.rakuten.co.jp/static/com/img/id/Rakuten_pc_20px@2x.png"
                    MockURLProtocol.stubImageRequests()

                    waitUntil { done in
                        dispatcher.fetchCarouselImage(for: urlString) { image in
                            expect(image).notTo(beNil())
                            let cachedImage = dispatcher.loadImageFromCache(for: URL(string: urlString)!)
                            expect(cachedImage).notTo(beNil())
                            done()
                        }
                    }
                }
            }

            context("when the URL is invalid") {
                it("returns nil") {
                    let urlString = "invalid-url"

                    waitUntil { done in
                        dispatcher.fetchCarouselImage(for: urlString) { image in
                            expect(image).to(beNil())
                            done()
                        }
                    }
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

class MockURLProtocol: URLProtocol {
    static var stubbedResponses: [URL: (Data?, HTTPURLResponse?, Error?)] = [:]
    static func stubResponse(for urlString: String, data: Data?, statusCode: Int = 200, headers: [String: String]? = nil) {
        guard let url = URL(string: urlString) else { return }
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )
        stubbedResponses[url] = (data, response, nil)
    }

    static func removeAllStubs() {
        stubbedResponses.removeAll()
    }

    static func stubImageRequests() {
        let sampleImageData = UIImage(named: "test-image", in: .unitTests, with: nil)?.pngData() ?? Data()
        stubResponse(for: "https://static.id.rakuten.co.jp/static/com/img/id/Rakuten_pc_20px@2x.png", data: sampleImageData)
    }

    static func stubCachedResponse(for urlString: String, data: Data? = nil, statusCode: Int = 200, headers: [String: String]? = nil) {
        guard let url = URL(string: urlString) else { return }
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )

        if let data = data {
            let cachedResponse = CachedURLResponse(response: response!, data: data)
            URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
        } else {
            let placeholderImageData = UIImage(named: "placeholder", in: .unitTests, with: nil)?.pngData() ?? Data()
            let cachedResponse = CachedURLResponse(response: response!, data: placeholderImageData)
            URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
        }
    }
}
