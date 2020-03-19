import Quick
import Nimble
@testable import RInAppMessaging

class UIColorExtensionsTests: QuickSpec {

    override func spec() {

        describe("UIColor+IAM") {

            context("when calling fromHexString method") {

                it("will return nil when string is too long") {
                    let color = UIColor(fromHexString: "FFFFFFF")
                    expect(color).to(beNil())
                }

                it("will return nil when string is too short") {
                    let color = UIColor(fromHexString: "FFFFF")
                    expect(color).to(beNil())
                }

                it("will return nil when string is empty") {
                    let color = UIColor(fromHexString: "")
                    expect(color).to(beNil())
                }

                it("will return nil when string has unsupported characters") {
                    var color = UIColor(fromHexString: "FFHFFF")
                    expect(color).to(beNil())
                    color = UIColor(fromHexString: "-FFFFF")
                    expect(color).to(beNil())
                }

                it("will return color with requested alpha value") {
                    let color = UIColor(fromHexString: "000000", alpha: 0.7)
                    var alpha: CGFloat = 0
                    color?.getRed(nil, green: nil, blue: nil, alpha: &alpha)
                    expect(alpha).to(equal(0.7))
                }

                it("will return full white color with FFFFFF") {
                    let color = UIColor(fromHexString: "FFFFFF")
                    expect(color).to(equal(UIColor.whiteRGB))
                }

                it("will return full black color with 000000") {
                    let color = UIColor(fromHexString: "000000")
                    expect(color).to(equal(UIColor.blackRGB))
                }

                it("will return expected color for given value") {
                    let color = UIColor(fromHexString: "FDAC10")
                    expect(color).to(equal(UIColor(red: 253.0/255.0,
                                                   green: 172.0/255.0,
                                                   blue: 16.0/255.0,
                                                   alpha: 1.0)))
                }

                it("will return expected color trimming whitespace characters from the string") {
                    let color = UIColor(fromHexString: "\n #FFFFFF\t")
                    expect(color).to(equal(UIColor.whiteRGB))
                }

                it("will return expected color even if string has are lower or upper case letters") {
                    let color = UIColor(fromHexString: "FFffFf")
                    expect(color).to(equal(UIColor.whiteRGB))
                }

                it("will return expected color for string with # prefix") {
                    let color = UIColor(fromHexString: "#FFFFFF")
                    expect(color).to(equal(UIColor.whiteRGB))
                }

                it("will return expected color for string without # prefix") {
                    let color = UIColor(fromHexString: "FFFFFF")
                    expect(color).to(equal(UIColor.whiteRGB))
                }
            }
        }
    }
}
