import Quick
import Nimble
@testable import RInAppMessaging

class ConfigurationClientTests: QuickSpec {

    override func spec() {
        describe("ConfigurationClient") {

            var mockReachability: MockReachability!
            var configurationClient: ConfigurationClient!

            beforeEach {
                mockReachability = MockReachability()
                configurationClient = ConfigurationClient(reachability: mockReachability, configURL: "https://google.com")
            }

            context("isConfigEnabled") {

                it("should return false when connection is not available") {
                    mockReachability.connectionStub = .unavailable
                    let isEnabled = configurationClient.isConfigEnabled(retryHandler: {})
                    expect(isEnabled).to(beFalse())
                }

                it("should make instance to register itself as Reachability observer when connection is not available") {
                    mockReachability.connectionStub = .unavailable
                    _ = configurationClient.isConfigEnabled(retryHandler: {})
                    expect(mockReachability.observers).to(containElementSatisfying({ $0.value === configurationClient }))
                }

                it("should make instance to unregister itself as Reachability observer when connection is restored") {
                    mockReachability.connectionStub = .unavailable
                    _ = configurationClient.isConfigEnabled(retryHandler: {})
                    expect(mockReachability.observers).to(containElementSatisfying({ $0.value === configurationClient }))
                    mockReachability.connectionStub = .wifi
                    expect(mockReachability.observers).toEventuallyNot(containElementSatisfying({ $0.value === configurationClient }))
                }

                it("should call retry handler when connection becomes available (cellular)") {
                    waitUntil(timeout: 1) { done in
                        mockReachability.connectionStub = .unavailable
                        let isEnabled = configurationClient.isConfigEnabled(retryHandler: {
                            done()
                        })
                        expect(isEnabled).to(beFalse())
                        mockReachability.connectionStub = .cellular
                    }
                }

                it("should call retry handler when connection becomes available (wifi)") {
                    waitUntil(timeout: 1) { done in
                        mockReachability.connectionStub = .unavailable
                        let isEnabled = configurationClient.isConfigEnabled(retryHandler: {
                            done()
                        })
                        expect(isEnabled).to(beFalse())
                        mockReachability.connectionStub = .wifi
                    }
                }
            }
        }
    }
}

private class MockReachability: ReachabilityType {
    var connectionStub = Reachability.Connection.unavailable {
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
