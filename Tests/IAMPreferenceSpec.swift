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

            context("when calling build()") {

                it("will populate all IAMPreference properties") {
                    let preference = IAMPreferenceBuilder()
                        .setUserId("userId")
                        .setRakutenId("rakutenId")
                        .setAccessToken("accessToken")
                        .setIDTrackingIdentifier("id")
                        .build() // using mocked .build() to allow accessToken and idTrackingIdentifier to be set together

                    expect(preference.accessToken).to(equal("accessToken"))
                    expect(preference.userId).to(equal("userId"))
                    expect(preference.rakutenId).to(equal("rakutenId"))
                    expect(preference.idTrackingIdentifier).to(equal("id"))
                }

                it("will contain nil properties for empty preference") {
                    let preference = IAMPreferenceBuilder().build()
                    expect(preference.accessToken).to(beNil())
                    expect(preference.userId).to(beNil())
                    expect(preference.rakutenId).to(beNil())
                    expect(preference.idTrackingIdentifier).to(beNil())
                }

                context("and assertions are checked") {
                    it("will thow an error if accessToken was specified without userId (for Rakuten apps)") {
                        let builder = IAMPreferenceBuilder().setAccessToken("access-token")
                        expect(builder.checkAssertions()).to(throwAssertion())
                    }

                    it("will thow an error if accessToken was specified with empty userId (for Rakuten apps)") {
                        let builder = IAMPreferenceBuilder().setAccessToken("access-token").setUserId("")
                        expect(builder.checkAssertions()).to(throwAssertion())
                    }

                    it("will thow an error if accessToken was specified with idTrackingIdentifier (for Rakuten apps)") {
                        let builder = IAMPreferenceBuilder().setAccessToken("access-token").setIDTrackingIdentifier("tracking-id")
                        expect(builder.checkAssertions()).to(throwAssertion())
                    }

                    it("will not thow an error for empty preference") {
                        let builder = IAMPreferenceBuilder()
                        expect(builder.checkAssertions()).toNot(throwAssertion())
                    }
                }
            }
        }
    }
}
