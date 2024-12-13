import Quick
import Nimble
import UIKit

@testable import RInAppMessaging

class CarouselModelHandlerSpec: QuickSpec {
    override func spec() {
        describe("CarouselModelHandler") {
            var sut: CarouselModelHandler!

            context("when initialized with nil images") {
                it("handles nil images and creates a valid imageDataList with nil image fields") {
                    let imageDetails = [
                        "2": ImageDetails(imgUrl: "link2", link: "Second image", altText: "http://example.com/2"),
                        "1": ImageDetails(imgUrl: "link1", link: "First image", altText: "http://example.com/1")
                    ]

                    let images: [UIImage?] = [nil, nil]

                    sut = CarouselModelHandler(data: imageDetails, images: images)

                    let result = sut.getImageDataList()

                    expect(result.count).to(equal(2))
                    expect(result[0].image).to(beNil())
                    expect(result[1].image).to(beNil())
                }
            }

            context("when data contains nil or missing fields") {
                it("handles missing altText or link gracefully") {
                    let imageDetails = [
                        "1": ImageDetails(imgUrl: "link1", link: "First image", altText: "http://example.com/1"),
                        "2": ImageDetails(imgUrl: "link2", link: nil, altText: "http://example.com/2"),
                        "3": ImageDetails(imgUrl: "link3", link: "Third image", altText: nil)
                    ]

                    let images: [UIImage?] = [
                        UIImage(named: "image1"),
                        UIImage(named: "image2"),
                        UIImage(named: "image3")
                    ]

                    sut = CarouselModelHandler(data: imageDetails, images: images)
                    let result = sut.getImageDataList()

                    expect(result.count).to(equal(3))
                    expect(result[2].altText).to(beNil())
                    expect(result[1].link).to(beNil())
                }
            }

            context("when initialized with mismatched data and images") {
                it("creates a list up to the minimum count of data and images") {
                    let imageDetails = [
                        "1": ImageDetails(imgUrl: "link1", link: "http://example.com/1", altText: "First image"),
                        "2": ImageDetails(imgUrl: "link2", link: "http://example.com/2", altText: "Second image"),
                        "3": ImageDetails(imgUrl: "link3", link: "http://example.com/3", altText: "Third image")
                    ]

                    let images: [UIImage?] = [UIImage(named: "image1")] // Only one image

                    sut = CarouselModelHandler(data: imageDetails, images: images)

                    let result = sut.getImageDataList()

                    expect(result.count).to(equal(1))
                    expect(result[0].altText).to(equal("First image"))
                }
            }

            context("when initialized with nil or empty fields in ImageDetails") {
                it("gracefully handles ImageDetails with nil or empty strings") {
                    let imageDetails = [
                        "1": ImageDetails(imgUrl: "", link: "", altText: nil),
                        "2": ImageDetails(imgUrl: "link2", link: "http://example.com/2", altText: "")
                    ]

                    let images: [UIImage?] = [
                        UIImage(named: "image1"),
                        UIImage(named: "image2")
                    ]

                    sut = CarouselModelHandler(data: imageDetails, images: images)
                    let result = sut.getImageDataList()

                    expect(result.count).to(equal(2))
                    expect(result[0].altText).to(beNil())
                    expect(result[0].link).to(equal(""))
                    expect(result[1].altText).to(equal(""))
                }
            }
        }
    }
}
