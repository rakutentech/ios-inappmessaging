import Quick
import Nimble
@testable import RInAppMessaging

class HeaderAttributesBuilderSpec: QuickSpec {

    override func spec() {

        describe("HeaderAttributesBuilder") {

            var builder: HeaderAttributesBuilder!
            let accountRepository = AccountRepository(userDataCache: UserDataCacheMock())
            let userInfoProvider = UserInfoProviderMock()
            accountRepository.setPreference(userInfoProvider)

            beforeEach {
                builder = HeaderAttributesBuilder()
                BundleInfoMock.reset()
                userInfoProvider.clear()
            }

            context("when calling addSubscriptionID") {

                it("should return false for empty subscription id") {
                    BundleInfoMock.inAppSubscriptionIdMock = ""
                    expect(builder.addSubscriptionID(bundleInfo: BundleInfoMock.self)).to(beFalse())
                }

                it("should return false for nil subscription id") {
                    BundleInfoMock.inAppSubscriptionIdMock = nil
                    expect(builder.addSubscriptionID(bundleInfo: BundleInfoMock.self)).to(beFalse())
                }

                it("should return true for any subscription id") {
                    BundleInfoMock.inAppSubscriptionIdMock = "some-id"
                    expect(builder.addSubscriptionID(bundleInfo: BundleInfoMock.self)).to(beTrue())
                }

                it("should append new header attribute") {
                    BundleInfoMock.inAppSubscriptionIdMock = "some-id"
                    builder.addSubscriptionID(bundleInfo: BundleInfoMock.self)
                    expect(builder.build()).to(elementsEqual([HeaderAttribute(key: Constants.Request.Header.subscriptionID, value: "some-id")]))
                }
            }

            context("when calling addAccessToken") {

                it("should return false for nil access token") {
                    userInfoProvider.accessToken = nil
                    expect(builder.addAccessToken(accountRepository: accountRepository)).to(beFalse())
                }

                it("should return true for any access token id") {
                    userInfoProvider.accessToken = "token"
                    expect(builder.addAccessToken(accountRepository: accountRepository)).to(beTrue())
                }

                it("should append new header attribute") {
                    userInfoProvider.accessToken = "token"
                    builder.addAccessToken(accountRepository: accountRepository)
                    expect(builder.build()).to(elementsEqual([HeaderAttribute(key: Constants.Request.Header.authorization, value: "OAuth2 token")]))
                }
            }

            context("when calling build") {

                it("should return empty array when nothing was set") {
                    expect(builder.build()).to(beEmpty())
                }

                it("should return array with all expected types") {
                    BundleInfoMock.inAppSubscriptionIdMock = "some-id"
                    userInfoProvider.accessToken = "token"

                    builder.addDeviceID()
                    builder.addSubscriptionID(bundleInfo: BundleInfoMock.self)
                    builder.addAccessToken(accountRepository: accountRepository)

                    expect(builder.build()).to(contain(HeaderAttribute(key: Constants.Request.Header.subscriptionID, value: "some-id")))
                    expect(builder.build()).to(contain(HeaderAttribute(key: Constants.Request.Header.authorization, value: "OAuth2 token")))
                    expect(builder.build()).to(containElementSatisfying({ $0.key == Constants.Request.Header.deviceID && !$0.value.isEmpty }))
                }
            }
        }
    }
}
