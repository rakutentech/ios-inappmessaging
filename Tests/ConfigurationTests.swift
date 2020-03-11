import Quick
import Nimble
@testable import RInAppMessaging

/// Tests for behavior of the SDK when supplied with different configuration responses.
class ConfigurationTests: QuickSpec {

    override func spec() {
        context("InAppMessaging") {

            var mockConfigurationClient: ConfigurationClient!
            var mockMessageMixer: MockMessageMixer!
            var dependencyManager: DependencyManager!

            func mockContainer() -> DependencyManager.Container {
                return DependencyManager.Container([
                    DependencyManager.ContainerElement(type: ConfigurationClient.self, factory: {
                        return mockConfigurationClient
                    }),
                    DependencyManager.ContainerElement(type: MessageMixerClientType.self, factory: {
                        return mockMessageMixer
                    })
                ])
            }

            beforeEach {
                mockMessageMixer = MockMessageMixer()
                dependencyManager = DependencyManager()
                dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager))
                dependencyManager.appendContainer(mockContainer())
            }

            it("is disabled because configuration returned false") {
                mockConfigurationClient = MockConfigurationClient(isConfigEnabled: false)
                RInAppMessaging.configure(dependencyManager: dependencyManager)

                expect(mockMessageMixer.enabledWasCalled).toEventuallyNot(equal(true))
            }

            it("is enabled because configuration returned true") {
                mockConfigurationClient = MockConfigurationClient(isConfigEnabled: true)
                RInAppMessaging.configure(dependencyManager: dependencyManager)

                expect(mockMessageMixer.enabledWasCalled).toEventually(equal(true))
            }
        }
    }
}

private class MockConfigurationClient: ConfigurationClient {
    private let isConfigEnabled: Bool

    init(isConfigEnabled: Bool) {
        self.isConfigEnabled = isConfigEnabled
        super.init(reachability: nil, configURL: "https://google.com")
    }

    override func isConfigEnabled(retryHandler: @escaping () -> Void) -> Bool {
        return self.isConfigEnabled
    }
}

private class MockMessageMixer: MessageMixerClientType {
    weak var errorDelegate: ErrorDelegate?
    var enabledWasCalled = false

    func ping() {
        self.enabledWasCalled = true
    }
}
