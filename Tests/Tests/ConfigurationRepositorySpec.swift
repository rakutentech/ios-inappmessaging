import Quick
import Nimble
import struct Foundation.URL
@testable import RInAppMessaging

class ConfigurationRepositorySpec: QuickSpec {

    override func spec() {

        describe("ConfigurationRepository") {

            var configurationRepository: ConfigurationRepository!

            beforeEach {
                configurationRepository = ConfigurationRepository()
            }

            it("will not return default URLSessionConfiguration") {
                expect(configurationRepository.defaultHttpSessionConfiguration).toNot(equal(.default))
            }

            it("will not hold any data until saved") {
                expect(configurationRepository.getEndpoints()).to(beNil())
                expect(configurationRepository.getRolloutPercentage()).to(beNil())
                expect(configurationRepository.getSubscriptionID()).to(beNil())
                expect(configurationRepository.getConfigEndpointURL()).to(beNil())
            }

            it("will throw an assertion when `isTooltipFeatureEnabled` is accessed before save") {
                expect(configurationRepository.isTooltipFeatureEnabled).to(throwAssertion())
            }

            context("when calling saveRemoteConfiguration()") {

                it("will properly save endpoint data") {
                    let endpoints = EndpointURL(ping: URL(string: "ping")!,
                                                displayPermission: URL(string: "displayPermission")!,
                                                impression: URL(string: "impression")!)
                    let config = ConfigEndpointData(rolloutPercentage: 100, endpoints: endpoints)
                    configurationRepository.saveRemoteConfiguration(config)

                    expect(configurationRepository.getEndpoints()).to(equal(endpoints))
                }

                it("will properly save enabled flag") {
                    let rolloutPercentage = 100
                    let config = ConfigEndpointData(rolloutPercentage: rolloutPercentage, endpoints: .empty)
                    configurationRepository.saveRemoteConfiguration(config)

                    expect(configurationRepository.getRolloutPercentage()).to(equal(rolloutPercentage))
                }
            }

            context("when calling saveIAMModuleConfiguration") {
                let sampleConfig = InAppMessagingModuleConfiguration(configurationURL: "http://config.url",
                                                                     subscriptionID: "sub-id",
                                                                     isTooltipFeatureEnabled: true)

                beforeEach {
                    configurationRepository.saveIAMModuleConfiguration(sampleConfig)
                }

                it("will properly save isTooltipFeatureEnabled flag") {
                    expect(configurationRepository.isTooltipFeatureEnabled).to(equal(sampleConfig.isTooltipFeatureEnabled))
                }

                it("will properly save subscription ID") {
                    expect(configurationRepository.getSubscriptionID()).to(equal(sampleConfig.subscriptionID))
                }

                it("will properly save config URL") {
                    expect(configurationRepository.getConfigEndpointURL()).to(equal(sampleConfig.configurationURL))
                }
            }
        }
    }
}
