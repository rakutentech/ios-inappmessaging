import Quick
import Nimble
import class UIKit.UIColor
@testable import RInAppMessaging

class UIColorExtensionsSpec: QuickSpec {
    override func spec() {
        describe("UIColor+IAM") {
            context("when calling brightness methods") {
                it("expect sRGB black to objectively be of 0 brightness") {
                    expect(UIColor.blackRGB.brightness) == 0
                    expect(UIColor.blackRGB.isBright).to(beFalse())
                }

                it("expect sRGB white to objectively be of 1 brightness") {
                    expect(UIColor.whiteRGB.brightness) == 1
                    expect(UIColor.whiteRGB.isBright).to(beTrue())
                }

                it("expect ext greyscale colour spaced black to objectively be of 0 brightness") {
                    expect(UIColor.black.brightness) == 0
                    expect(UIColor.black.isBright).to(beFalse())
                }

                it("expect ext greyscale colour spaced white to objectively be of 1 brightness") {
                    expect(UIColor.white.brightness) == 1
                    expect(UIColor.white.isBright).to(beTrue())
                }
            }

            context("when calling isComparable method") {
                it("should return true for the same colors") {
                    expect(UIColor.white.isComparable(to: .white)).to(beTrue())
                    expect(UIColor.blue.isComparable(to: .blue)).to(beTrue())
                }
                it("should return false for obviously different, contrasting colors") {
                    expect(UIColor.white.isComparable(to: .black)).to(beFalse())
                    expect(UIColor.green.isComparable(to: .blue)).to(beFalse())
                }
                it("should return true for very similar colors") {
                    expect(UIColor.black.isComparable(to: UIColor(red: 5/255.0, green: 5/255.0, blue: 5/255.0, alpha: 1))).to(beTrue())
                    expect(UIColor(red: 1/255.0, green: 2/255.0, blue: 3/255.0, alpha: 1).isComparable(
                        to: UIColor(red: 1/255.0, green: 3/255.0, blue: 2/255.0, alpha: 1))).to(beTrue())
                }
            }
        }
    }
}
