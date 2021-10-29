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
            }

            it("will properly save endpoint data") {
                let endpoints = EndpointURL(ping: URL(string: "ping")!,
                                            displayPermission: URL(string: "displayPermission")!,
                                            impression: URL(string: "impression")!)
                let config = ConfigData(rolloutPercentage: 100, endpoints: endpoints)
                configurationRepository.saveConfiguration(config)

                expect(configurationRepository.getEndpoints()).to(equal(endpoints))
            }

            it("will properly save enabled flag") {
                let rolloutPercentage = 100
                let config = ConfigData(rolloutPercentage: rolloutPercentage, endpoints: .empty)
                configurationRepository.saveConfiguration(config)

                expect(configurationRepository.getRolloutPercentage()).to(equal(rolloutPercentage))
            }
        }
    }
}
