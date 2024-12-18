import Quick
import Nimble
import UIKit
@testable import RInAppMessaging

class CarouselCellSpec: QuickSpec {
    override func spec() {
        var cell: CarouselCell!

        beforeEach {
            cell = CarouselCell(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        }

        describe("CarouselCell") {
            it("should have the correct identifier") {
                expect(CarouselCell.identifier).to(equal("CarouselCell"))
            }

            it("should initialize with an imageView and textLabel") {
                expect(cell.contentView.subviews).to(contain(cell.imageView))
                expect(cell.contentView.subviews).to(contain(cell.textLabel))
            }

            it("should layout subviews correctly") {
                cell.layoutSubviews()

                expect(cell.imageView.frame).to(equal(cell.contentView.bounds))

                let maxTextWidth = cell.contentView.bounds.width * 0.8
                let textSize = cell.textLabel.sizeThatFits(CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude))
                let textX = (cell.contentView.bounds.width - textSize.width) / 2
                let textY = (cell.contentView.bounds.height - textSize.height) / 2
                expect(cell.textLabel.frame).to(equal(CGRect(x: textX, y: textY, width: textSize.width, height: textSize.height)))
            }
            context("when configured with an image") {
                it("should display the image and hide the textLabel") {
                    let image = UIImage()
                    cell.configure(with: image, altText: "Alt Text")

                    expect(cell.imageView.image).to(equal(image))
                    expect(cell.textLabel.isHidden).to(beTrue())
                }

                it("should not display the alt text") {
                    let image = UIImage()
                    cell.configure(with: image, altText: "Alt Text")

                    expect(cell.textLabel.text).to(equal("Alt Text"))
                    expect(cell.textLabel.isHidden).to(beTrue())
                }
            }

            context("when configured without an image") {
                it("should display the alt text and imageView should have nil image") {
                    cell.configure(with: nil, altText: "Alt Text")

                    expect(cell.imageView.image).to(beNil())
                    expect(cell.textLabel.isHidden).to(beFalse())
                    expect(cell.textLabel.text).to(equal("Alt Text"))
                }
            }

            context("when configured with an empty alt text") {
                it("should display an empty alt text") {
                    cell.configure(with: nil, altText: "")

                    expect(cell.textLabel.text).to(equal(""))
                    expect(cell.textLabel.isHidden).to(beFalse())
                }
            }

            context("when configured with a nil alt text") {
                it("should display the default alt text") {
                    cell.configure(with: nil, altText: nil)

                    expect(cell.textLabel.text).to(equal("carousel_image_load_error".localized))
                    expect(cell.textLabel.isHidden).to(beFalse())
                }
            }

            context("when layoutSubviews is called multiple times") {
                it("should layout subviews correctly each time") {
                    cell.layoutSubviews()
                    cell.layoutSubviews()

                    expect(cell.imageView.frame).to(equal(cell.contentView.bounds))

                    let maxTextWidth = cell.contentView.bounds.width * 0.8
                    let textSize = cell.textLabel.sizeThatFits(CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude))
                    let textX = (cell.contentView.bounds.width - textSize.width) / 2
                    let textY = (cell.contentView.bounds.height - textSize.height) / 2
                    expect(cell.textLabel.frame).to(equal(CGRect(x: textX, y: textY, width: textSize.width, height: textSize.height)))
                }
            }
        }
    }
}
