import Quick
import Nimble
import class UIKit.UIColor
@testable import RInAppMessaging

class UIColorExtensionsSpec: QuickSpec {
    override func spec() {
        describe("UIColor+IAM") {
            context("when calling brightness methods") {
                it("expect black to objectively be of 0/1 brightness") {
                    expect(UIColor.black.brightness) == 0
                    expect(UIColor.black.isBright).to(beFalse())
                }

                it("expect white to objectively be of 1/1 brightness") {
                    expect(UIColor.white.brightness) == 1
                    expect(UIColor.white.isBright).to(beTrue())
                }
            }
        }
    }
}
