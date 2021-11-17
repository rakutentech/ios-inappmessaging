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
        }
    }
}
