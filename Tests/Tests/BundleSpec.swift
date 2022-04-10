import Foundation
import Quick
import Nimble
@testable import RInAppMessaging

class BundleSpec: QuickSpec {

    override func spec() {
        describe("BundleInfo") {

            it("should return expected applicationId") {
                expect(BundleInfo.applicationId).to(equal("jp.co.rakuten.inappmessaging.demo"))
            }

            it("should return expected appVersion") {
                expect(BundleInfo.appVersion).to(equal("1.0"))
            }

            it("should return a valid inAppSdkVersion") {
                // swiftlint:disable:next line_length
                let semverRegex = #"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$"#
                expect(BundleInfo.inAppSdkVersion).to(match(semverRegex))
            }
        }

        describe("Bundle extensions") {
            it("should return non-nil value for sdkAssets property") {
                expect(Bundle.sdkAssets).toNot(beNil())
            }
        }
    }
}
