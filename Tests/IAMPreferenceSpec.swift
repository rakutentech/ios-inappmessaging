import Quick
import Nimble
@testable import RInAppMessaging

class IAMPreferenceSpec: QuickSpec {

    override func spec() {

        describe("IAMPreference") {

            let somePreference = IAMPreferenceBuilder()
                .setUserId("userId")
                .setRakutenId(nil)
                .setAccessToken("accessToken")
                .build()
            let emptyPreference = IAMPreferenceBuilder().build()

            context("when calling diff()") {

                it("will return a field if compared with nil object") {
                    let diff = somePreference.diff(nil)
                    expect(diff).to(equal([.userId, .accessToken]))
                }

                it("will return a field if the other field is nil") {
                    let aPreference = IAMPreferenceBuilder()
                        .setUserId(nil)
                        .setRakutenId("rakutenId")
                        .setAccessToken("accessToken")
                        .build()
                    let diff = aPreference.diff(somePreference)
                    expect(diff).to(elementsEqualOrderAgnostic([.userId, .rakutenId]))
                }

                it("will be commutative (except nil value)") {
                    let diffA = somePreference.diff(emptyPreference)
                    let diffB = emptyPreference.diff(somePreference)
                    expect(diffA).to(elementsEqual(diffB))
                }

                it("will return an empty array if fields are the same") {
                    let diff = somePreference.diff(somePreference)
                    expect(diff).to(beEmpty())
                }
            }
        }
    }
}
