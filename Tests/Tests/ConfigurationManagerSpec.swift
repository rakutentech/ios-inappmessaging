import Foundation
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
            var errorDelegate: ErrorDelegateMock!

            beforeEach {
                reachability = ReachabilityMock()
                configurationService = ConfigurationServiceMock()
                configurationRepository = ConfigurationRepository()
                errorDelegate = ErrorDelegateMock()
                configurationManager = ConfigurationManager(reachability: reachability,
                                                            configurationService: configurationService,
                                                            configurationRepository: configurationRepository,
                                                            resumeQueue: DispatchQueue(label: "iam.test.request"))
                configurationManager.errorDelegate = errorDelegate
            }

            context("fetchAndSaveConfigData") {

                context("when configurationService is nil (when config URL is missing)") {
                    beforeEach {
                        configurationManager = ConfigurationManager(reachability: reachability,
                                                                    configurationService: nil,
                                                                    configurationRepository: configurationRepository,
                                                                    resumeQueue: DispatchQueue(label: "iam.test.request"))
                        configurationManager.errorDelegate = errorDelegate
                    }

                    it("should report an error") {
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    it("should call completion with rolloutPercentage 0") {
                        waitUntil { done in
                            configurationManager.fetchAndSaveConfigData(completion: { configData in
                                expect(configData.rolloutPercentage).to(equal(0))
                                done()
                            })
                        }
                    }
                }

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
                        Constants.Retry.Tests.setInitialDelayMS(1000)
                        Constants.Retry.Tests.setBackOffUpperBoundSeconds(1)
                    }

                    afterEach {
                        Constants.Retry.Tests.setDefaults()
                    }

                    it("should retry") {
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(configurationService.getConfigDataCallCount).to(equal(1))
                        expect(configurationService.getConfigDataCallCount).toEventually(equal(2), timeout: .seconds(2))
                    }

                    it("should call completion after retry attempt was successful") {
                        waitUntil(timeout: .seconds(2)) { done in
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

                    it("should not report .tooManyRequestsError error") {
                        configurationService.mockedError = .tooManyRequestsError
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(errorDelegate.wasErrorReceived).to(beFalse())
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

                    it("should report .missingOrInvalidSubscriptionId error") {
                        configurationService.mockedError = .missingOrInvalidSubscriptionId
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
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

                    it("should report .unknownSubscriptionId error") {
                        configurationService.mockedError = .unknownSubscriptionId
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    it("should not retry for .invalidRequestError error") {
                        configurationService.mockedError = .invalidRequestError(422)
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(configurationManager.scheduledTask).toAfterTimeout(beNil())
                    }

                    it("should return disable response for .invalidRequestError error") {
                        configurationService.mockedError = .invalidRequestError(422)
                        waitUntil { done in
                            configurationManager.fetchAndSaveConfigData(completion: { config in
                                expect(config.rolloutPercentage).to(equal(0))
                                done()
                            })
                        }
                    }

                    it("should report .invalidRequestError error") {
                        configurationService.mockedError = .invalidRequestError(422)
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    it("should retry for .internalServerError error") {
                        configurationService.mockedError = .internalServerError(500)
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(configurationManager.scheduledTask).toEventuallyNot(beNil())
                    }

                    it("should retry 3 times for .internalServerError error") {
                        configurationService.mockedError = .internalServerError(500)
                        var returnedConfig: ConfigData?
                        configurationManager.fetchAndSaveConfigData(completion: { config in
                            returnedConfig = config
                        })
                        expect(configurationManager.scheduledTask).toEventuallyNot(beNil())
                        expect(configurationService.getConfigDataCallCount).toEventually(equal(4), timeout: .seconds(12))
                        expect(returnedConfig).toEventuallyNot(beNil())
                        expect(configurationManager.scheduledTask).to(beNil())
                    }

                    it("should report .invalidRequestError error") {
                        configurationService.mockedError = .internalServerError(500)
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    it("should report .jsonDecodingError error") {
                        configurationService.mockedError = .jsonDecodingError(NSError.emptyError)
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }

                    it("should not retry for .jsonDecodingError error") {
                        configurationService.mockedError = .jsonDecodingError(NSError.emptyError)
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(configurationManager.scheduledTask).toAfterTimeout(beNil())
                    }

                    it("should return disable response for .jsonDecodingError error") {
                        configurationService.mockedError = .jsonDecodingError(NSError.emptyError)
                        waitUntil { done in
                            configurationManager.fetchAndSaveConfigData(completion: { config in
                                expect(config.rolloutPercentage).to(equal(0))
                                done()
                            })
                        }
                    }

                    it("should retry for .requestError error") {
                        configurationService.mockedError = .requestError(.unknown)
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(configurationManager.scheduledTask).toEventuallyNot(beNil())
                    }

                    it("should report .requestError error") {
                        configurationService.mockedError = .requestError(.unknown)
                        configurationManager.fetchAndSaveConfigData(completion: { _ in })
                        expect(errorDelegate.wasErrorReceived).to(beTrue())
                    }
                }
            }
        }
    }
}
