import Quick
import Nimble
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
                expect(configurationRepository.getIsEnabledStatus()).to(beNil())
            }

            it("will properly save endpoint data") {
                let endpoints = EndpointURL(ping: URL(string: "ping")!,
                                            displayPermission: URL(string: "displayPermission")!,
                                            impression: URL(string: "impression")!)
                let config = ConfigData(enabled: true, endpoints: endpoints)
                configurationRepository.saveConfiguration(config)

                expect(configurationRepository.getEndpoints()).to(equal(endpoints))
            }

            it("will properly save enabled flag") {
                let enabled = true
                let config = ConfigData(enabled: enabled, endpoints: .empty)
                configurationRepository.saveConfiguration(config)

                expect(configurationRepository.getIsEnabledStatus()).to(equal(enabled))
            }
        }
    }
}
