import Quick
import Nimble
@testable import RInAppMessaging

class ConfigurationManagerTests: QuickSpec {

    override func spec() {
        describe("ConfigurationManager") {

            var reachability: ReachabilityMock!
            var configurationService: ConfigurationServiceMock!
            var configurationRepository: ConfigurationRepositoryMock!
            var configurationManager: ConfigurationManager!

            beforeEach {
                reachability = ReachabilityMock()
                configurationService = ConfigurationServiceMock()
                configurationRepository = ConfigurationRepositoryMock()
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
                        expect(wasCompletionCalled).toEventuallyNot(beTrue())
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
                    expect(configurationRepository.configuration).to(beNil())
                    configurationManager.fetchAndSaveConfigData(completion: { _ in })
                    expect(configurationRepository.configuration).toNot(beNil())
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

private class ReachabilityMock: ReachabilityType {
    var connectionStub = Reachability.Connection.wifi {
        didSet {
            observers.forEach { $0.value?.reachabilityChanged(self) }
        }
    }
    var connection: Reachability.Connection {
        return connectionStub
    }

    var observers = [WeakWrapper<ReachabilityObserver>]()

    func addObserver(_ observer: ReachabilityObserver) {
        observers.append(WeakWrapper(value: observer))
    }
    func removeObserver(_ observer: ReachabilityObserver) {
        observers.removeAll { $0.value === observer }
    }
}

private class ConfigurationServiceMock: ConfigurationServiceType {
    var getConfigDataCallCount = 0
    var simulateRequestFailure = false

    func getConfigData() -> Result<ConfigData, ConfigurationServiceError> {
        getConfigDataCallCount += 1

        guard !simulateRequestFailure else {
            return .failure(.requestError(.unknown))
        }
        let emptyURL = URL(string: "about:blank")!
        let emptyEndpoints = EndpointURL(ping: emptyURL,
                                         displayPermission: emptyURL,
                                         impression: emptyURL)
        return .success(ConfigData(enabled: true, endpoints: emptyEndpoints))
    }
}

private class ConfigurationRepositoryMock: ConfigurationRepositoryType {
    var defaultHttpSessionConfiguration: URLSessionConfiguration = .ephemeral
    var configuration: ConfigData?

    func saveConfiguration(_ data: ConfigData) {
        configuration = data
    }

    func getEndpoints() -> EndpointURL? {
        return configuration?.endpoints
    }

    func getIsEnabledStatus() -> Bool? {
        return configuration?.enabled
    }
}
