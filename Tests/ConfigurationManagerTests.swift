import Quick
import Nimble
@testable import RInAppMessaging

class ConfigurationManagerTests: QuickSpec {

    override func spec() {
        describe("ConfigurationManager") {

            var reachability: ReachabilityMock!
            var configurationService: ConfigurationServiceMock!
            var configurationRepository: ConfigurationRepository!
            var configurationManager: ConfigurationManager!

            beforeEach {
                reachability = ReachabilityMock()
                configurationService = ConfigurationServiceMock()
                configurationRepository = ConfigurationRepository()
                configurationManager = ConfigurationManager(reachability: reachability,
                                                            configurationService: configurationService,
                                                            configurationRepository: configurationRepository)
            }

            context("fetchAndSaveConfigData") {

                context("when connection is not available") {
                    beforeEach {
                        reachability.connectionStub = .unavailable
                    }

                    it("should register itself as Reachability observer") {
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(reachability.observers).to(containElementSatisfying({ $0.value === configurationManager }))
                    }

                    it("should unregister itself as Reachability observer when connection is restored") {
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(reachability.observers).to(containElementSatisfying({ $0.value === configurationManager }))
                        reachability.connectionStub = .wifi
                        expect(reachability.observers).toEventuallyNot(containElementSatisfying({ $0.value === configurationManager }))
                    }

                    it("should not call completion handler") {
                        var wasCompletionCalled = false
                        configurationManager.fetchAndSaveConfigData(completion: { _ in
                            wasCompletionCalled = true
                        })
                        expect(wasCompletionCalled).toAfterTimeout(beFalse())
                    }

                    it("should call retry handler when connection becomes available (cellular)") {
                        waitUntil(timeout: 1) { done in
                            configurationManager.fetchAndSaveConfigData(completion: { _ in
                                done()
                            })
                            reachability.connectionStub = .cellular
                        }
                    }

                    it("should call retry handler when connection becomes available (wifi)") {
                        waitUntil(timeout: 1) { done in
                            configurationManager.fetchAndSaveConfigData(completion: { _ in
                                done()
                            })
                            reachability.connectionStub = .wifi
                        }
                    }
                }

                it("should save fetched configuration in the repository object") {
                    expect(configurationRepository.getIsEnabledStatus()).to(beNil())
                    configurationManager.fetchAndSaveConfigData(completion: { _ in })
                    expect(configurationRepository.getIsEnabledStatus()).to(beTrue())
                }

                it("should retry after request failure") {
                    configurationService.simulateRequestFailure = true
                    configurationManager.fetchAndSaveConfigData(completion: { _ in })
                    expect(configurationService.getConfigDataCallCount).to(equal(1))
                    expect(configurationService.getConfigDataCallCount).toEventually(equal(2), timeout: 11)
                }

                it("should call completion after retry attempt was successful") {
                    waitUntil(timeout: 11) { done in
                        configurationService.simulateRequestFailure = true
                        configurationManager.fetchAndSaveConfigData(completion: { _ in
                            done()
                        })
                        configurationService.simulateRequestFailure = false
                    }
                }
            }
        }
    }
}
