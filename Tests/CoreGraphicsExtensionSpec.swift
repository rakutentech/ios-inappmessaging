import Quick
import Nimble
@testable import RInAppMessaging

class CoreGraphicsExtensionsSpec: QuickSpec {
    override func spec() {
        describe("CGSize+IAM") {
            context("when calling integral property") {
                it("will return a CGSize with whole integers") {
                    let given = CGSize(width: 0.23, height: 2.34)
                    let ref = CGRect(origin: .zero, size: given).integral.size
                    expect(ref).to(equal(given.integral))
                    expect(ref).to(equal(CGSize(width: 1, height: 3)))
                }

                it("will return a max CGSize max magnitude") {
                    let given = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                    let ref = CGRect(origin: .zero, size: given).integral.size
                    expect(ref).to(equal(given.integral))
                    expect(ref).to(equal(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)))
                }

                it("will return a 1x1 CGSize with least normal magnitude") {
                    let given = CGSize(width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude)
                    let ref = CGRect(origin: .zero, size: given).integral.size
                    expect(ref).to(equal(given.integral))
                    expect(ref).to(equal(CGSize(width: 1, height: 1)))
                }

                it("will return a 1x1 CGSize with least non-zero magnitude") {
                    let given = CGSize(width: CGFloat.leastNonzeroMagnitude, height: CGFloat.leastNonzeroMagnitude)
                    let ref = CGRect(origin: .zero, size: given).integral.size
                    expect(ref).to(equal(given.integral))
                    expect(ref).to(equal(CGSize(width: 1, height: 1)))
                }
            }
        }
    }
}
