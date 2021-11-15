import Quick
import Nimble
#if canImport(RSDKUtilsNimble)
import RSDKUtilsNimble // SPM version
#else
import RSDKUtils
#endif
@testable import RInAppMessaging

class UserInfoProviderSpec: QuickSpec {

    override func spec() {

        describe("UserInfoProvider") {

            let userInfoProvider = UserInfoProviderMock()

            beforeEach {
                userInfoProvider.clear()
            }

            context("when calling userIdentifiers") {
                it("will return empty array for null values") {
                    expect(userInfoProvider.userIdentifiers).to(beEmpty())
                }

                it("will return empty array for empty string values") {
                    userInfoProvider.userID = ""
                    userInfoProvider.idTrackingIdentifier = ""
                    expect(userInfoProvider.userIdentifiers).to(beEmpty())
                }

                it("will return empty array if only accessToken is provided") {
                    userInfoProvider.accessToken = "token"
                    expect(userInfoProvider.userIdentifiers).to(beEmpty())
                }

                it("will return array containing userID") {
                    userInfoProvider.userID = "user"
                    expect(userInfoProvider.userIdentifiers)
                        .to(elementsEqualOrderAgnostic([UserIdentifier(type: .userId, identifier: "user")]))
                }

                it("will return array containing idTrackingIdentifier") {
                    userInfoProvider.idTrackingIdentifier = "tracking-id"
                    expect(userInfoProvider.userIdentifiers)
                        .to(elementsEqualOrderAgnostic([UserIdentifier(type: .idTrackingIdentifier, identifier: "tracking-id")]))
                }

                it("will return array containing all identifiers") {
                    userInfoProvider.userID = "user"
                    userInfoProvider.idTrackingIdentifier = "tracking-id"
                    expect(userInfoProvider.userIdentifiers)
                        .to(elementsEqualOrderAgnostic([UserIdentifier(type: .userId, identifier: "user"),
                                                       UserIdentifier(type: .idTrackingIdentifier, identifier: "tracking-id")]))
                }
            }

            context("when checking equality") {
                var userInfoProviderA: UserInfoProviderMock!
                var userInfoProviderB: UserInfoProviderMock!

                beforeEach {
                    userInfoProviderA = UserInfoProviderMock()
                    userInfoProviderB = UserInfoProviderMock()
                }

                it("will return true for nil objects") {
                    userInfoProviderA = nil
                    userInfoProviderB = nil
                    expect(userInfoProviderA == userInfoProviderB).to(beTrue())
                }

                it("will return false for nil and empty object") {
                    userInfoProviderA = nil
                    expect(userInfoProviderA == userInfoProviderB).to(beFalse())
                }

                it("will return true for the same userIds") {
                    userInfoProviderA.userID = "user"
                    userInfoProviderB.userID = "user"
                    expect(userInfoProviderA == userInfoProviderB).to(beTrue())
                }

                it("will return true for nil end empty userId") {
                    userInfoProviderA.userID = nil
                    userInfoProviderB.userID = ""
                    expect(userInfoProviderA == userInfoProviderB).to(beTrue())
                }

                it("will return false for different userIds") {
                    userInfoProviderA.userID = "userA"
                    userInfoProviderB.userID = "userB"
                    expect(userInfoProviderA == userInfoProviderB).to(beFalse())
                }

                it("will return true for the same idTrackingIdentifiers") {
                    userInfoProviderA.idTrackingIdentifier = "tracking-id"
                    userInfoProviderB.idTrackingIdentifier = "tracking-id"
                    expect(userInfoProviderA == userInfoProviderB).to(beTrue())
                }

                it("will return true for nil end empty isTrackingIdentifier") {
                    userInfoProviderA.idTrackingIdentifier = nil
                    userInfoProviderB.idTrackingIdentifier = ""
                    expect(userInfoProviderA == userInfoProviderB).to(beTrue())
                }

                it("will return false for different idTrackingIdentifiers") {
                    userInfoProviderA.idTrackingIdentifier = "identityA"
                    userInfoProviderB.idTrackingIdentifier = "identityB"
                    expect(userInfoProviderA == userInfoProviderB).to(beFalse())
                }

                it("will return true for the same accessTokens") {
                    userInfoProviderA.accessToken = "token"
                    userInfoProviderB.accessToken = "token"
                    expect(userInfoProviderA == userInfoProviderB).to(beTrue())
                }

                it("will return true for nil end empty accessToken") {
                    userInfoProviderA.accessToken = nil
                    userInfoProviderB.accessToken = ""
                    expect(userInfoProviderA == userInfoProviderB).to(beTrue())
                }

                it("will return true (!) for different accessTokens") {
                    // Disclaimer: User is not defined by its access token
                    userInfoProviderA.accessToken = "tokenA"
                    userInfoProviderB.accessToken = "tokenB"
                    expect(userInfoProviderA == userInfoProviderB).to(beTrue())
                }

                it("will return false if one identifier is different") {
                    userInfoProviderA.idTrackingIdentifier = "tracking-id"
                    userInfoProviderB.idTrackingIdentifier = "tracking-id"
                    userInfoProviderA.userID = "userA"
                    userInfoProviderB.userID = "userB"
                    expect(userInfoProviderA == userInfoProviderB).to(beFalse())

                    userInfoProviderA.userID = "user"
                    userInfoProviderB.userID = "user"
                    userInfoProviderA.idTrackingIdentifier = "identityA"
                    userInfoProviderB.idTrackingIdentifier = "identityB"
                    expect(userInfoProviderA == userInfoProviderB).to(beFalse())
                }

                it("will return true if only accessToken is different") {
                    userInfoProviderA.idTrackingIdentifier = "tracking-id"
                    userInfoProviderB.idTrackingIdentifier = "tracking-id"
                    userInfoProviderA.userID = "user"
                    userInfoProviderB.userID = "user"
                    userInfoProviderA.accessToken = "tokenA"
                    userInfoProviderB.accessToken = "tokenB"
                    expect(userInfoProviderA == userInfoProviderB).to(beTrue())
                }
            }
        }
    }
}
