import Quick
import Nimble
@testable import RInAppMessaging

class LocaleSpec: QuickSpec {

    override func spec() {

        describe("Locale+IAM extension") {

            context("when using normalizedIdentifier") {
                let locale = Locale(identifier: "en_US_POSIX@calendar=japanese")

                it("will replace occurences of `_` with `-` in identifier") {
                    expect(locale.normalizedIdentifier.caseInsensitiveCompare("en-US-POSIX")).to(equal(.orderedSame))
                }

                it("will convert identifier to lowercase string") {
                    expect(locale.normalizedIdentifier.rangeOfCharacter(from: CharacterSet.uppercaseLetters)).to(beNil())
                }

                it("will remove calendar information from identifier") {
                    expect(locale.normalizedIdentifier.range(of: "@calendar")).to(beNil())
                }
            }
        }
    }
}
