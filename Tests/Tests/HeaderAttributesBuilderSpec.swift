import Quick
import Nimble
@testable import RInAppMessaging

class HeaderAttributesBuilderSpec: QuickSpec {

    override func spec() {

        describe("HeaderAttributesBuilder") {

            var builder: HeaderAttributesBuilder!
            let accountRepository = AccountRepository(userDataCache: UserDataCacheMock())
            let userInfoProvider = UserInfoProviderMock()
            var configurationRepository: ConfigurationRepository!

            accountRepository.setPreference(userInfoProvider)

            beforeEach {
                builder = HeaderAttributesBuilder()
                BundleInfoMock.reset()
                userInfoProvider.clear()
                configurationRepository = ConfigurationRepository()
            }

            context("when calling addSubscriptionID") {

                it("should return false for empty subscription id") {
                    configurationRepository.saveIAMModuleConfiguration(
                        InAppMessagingModuleConfiguration(subscriptionID: ""))
                    expect(builder.addSubscriptionID(configurationRepository: configurationRepository)).to(beFalse())
                }

                it("should return false for nil subscription id") {
                    configurationRepository.saveIAMModuleConfiguration(
                        InAppMessagingModuleConfiguration(subscriptionID: nil))
                    expect(builder.addSubscriptionID(configurationRepository: configurationRepository)).to(beFalse())
                }

                it("should return true for any subscription id") {
                    configurationRepository.saveIAMModuleConfiguration(
                        InAppMessagingModuleConfiguration(subscriptionID: "some-id"))
                    expect(builder.addSubscriptionID(configurationRepository: configurationRepository)).to(beTrue())
                }

                it("should append new header attribute") {
                    configurationRepository.saveIAMModuleConfiguration(
                        InAppMessagingModuleConfiguration(subscriptionID: "some-id"))
                    builder.addSubscriptionID(configurationRepository: configurationRepository)
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
                    configurationRepository.saveIAMModuleConfiguration(
                        InAppMessagingModuleConfiguration(subscriptionID: "some-id"))
                    userInfoProvider.accessToken = "token"

                    builder.addDeviceID()
                    builder.addSubscriptionID(configurationRepository: configurationRepository)
                    builder.addAccessToken(accountRepository: accountRepository)

                    expect(builder.build()).to(contain(HeaderAttribute(key: Constants.Request.Header.subscriptionID, value: "some-id")))
                    expect(builder.build()).to(contain(HeaderAttribute(key: Constants.Request.Header.authorization, value: "OAuth2 token")))
                    expect(builder.build()).to(containElementSatisfying({ $0.key == Constants.Request.Header.deviceID && !$0.value.isEmpty }))
                }
            }
        }
    }
}
