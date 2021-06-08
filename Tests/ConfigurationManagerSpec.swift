import Quick
import Nimble
@testable import RInAppMessaging

class ConfigurationManagerSpec: QuickSpec {

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
                                                            configurationRepository: configurationRepository,
                                                            resumeQueue: DispatchQueue(label: "iam.test.request"))
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
                        waitUntil { done in
                            configurationManager.fetchAndSaveConfigData(completion: { _ in
                                done()
                            })
                            reachability.connectionStub = .cellular
                        }
                    }

                    it("should call retry handler when connection becomes available (wifi)") {
                        waitUntil { done in
                            configurationManager.fetchAndSaveConfigData(completion: { _ in
                                done()
                            })
                            reachability.connectionStub = .wifi
                        }
                    }
                }

                it("should save fetched configuration in the repository object") {
                    expect(configurationRepository.getRolloutPercentage()).to(beNil())
                    configurationManager.fetchAndSaveConfigData(completion: { _ in })
                    expect(configurationRepository.getRolloutPercentage()).to(equal(100))
                }

                context("when request failed") {

                    beforeEach {
                        configurationService.simulateRequestFailure = true
                    }

                    it("should retry") {
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(configurationService.getConfigDataCallCount).to(equal(1))
                        expect(configurationService.getConfigDataCallCount).toEventually(equal(2), timeout: .seconds(11))
                    }

                    it("should call completion after retry attempt was successful") {
                        waitUntil(timeout: .seconds(11)) { done in
                            configurationManager.fetchAndSaveConfigData(completion: { _ in
                                done()
                            })
                            configurationService.simulateRequestFailure = false
                        }
                    }

                    it("should retry for .tooManyRequestsError error") {
                        configurationService.mockedError = .tooManyRequestsError
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(configurationManager.scheduledTask).toEventuallyNot(beNil())
                    }

                    it("should not retry for .missingOrInvalidSubscriptionId error") {
                        configurationService.mockedError = .missingOrInvalidSubscriptionId
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(configurationManager.scheduledTask).toAfterTimeout(beNil())
                    }

                    it("should return disable response for .missingOrInvalidSubscriptionId error") {
                        configurationService.mockedError = .missingOrInvalidSubscriptionId
                        waitUntil { done in
                            configurationManager.fetchAndSaveConfigData(completion: { config in
                                expect(config.rolloutPercentage).to(equal(0))
                                done()
                            })
                        }
                    }

                    it("should not retry for .unknownSubscriptionId error") {
                        configurationService.mockedError = .unknownSubscriptionId
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(configurationManager.scheduledTask).toAfterTimeout(beNil())
                    }

                    it("should return disable response for .unknownSubscriptionId error") {
                        configurationService.mockedError = .unknownSubscriptionId
                        waitUntil { done in
                            configurationManager.fetchAndSaveConfigData(completion: { config in
                                expect(config.rolloutPercentage).to(equal(0))
                                done()
                            })
                        }
                    }
                }
            }
        }
    }
}
