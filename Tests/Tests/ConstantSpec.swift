import Foundation
import Quick
import Nimble
@testable import RInAppMessaging

class ConstantSpec: QuickSpec {

    override func spec() {
        describe("Constant") {

            let constant = Constants.self

            it("should return a valid inAppSdkVersion") {
                // swiftlint:disable:next line_length
                let semverRegex = #"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$"#
                expect(constant.Versions.sdkVersion).to(match(semverRegex))
            }
        }
    }
}
