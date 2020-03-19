import Quick
import Nimble
@testable import RInAppMessaging

/// Tests for behavior of the SDK when supplied with different configuration responses.
class ConfigurationTests: QuickSpec {

    override func spec() {
        context("InAppMessaging") {

            var configurationManager: ConfigurationManagerMock!
            var mockMessageMixer: MessageMixerMock!
            var dependencyManager: DependencyManager!

            func mockContainer() -> DependencyManager.Container {
                return DependencyManager.Container([
                    DependencyManager.ContainerElement(type: ConfigurationManagerType.self, factory: {
                        return configurationManager
                    }),
                    DependencyManager.ContainerElement(type: MessageMixerServiceType.self, factory: {
                        return mockMessageMixer
                    })
                ])
            }

            beforeEach {
                mockMessageMixer = MessageMixerMock()
                dependencyManager = DependencyManager()
                configurationManager = ConfigurationManagerMock()
                RInAppMessaging.initializedModule = nil
                dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager))
                dependencyManager.appendContainer(mockContainer())
            }

            context("when configuration returned false") {

                it("will disable module") {
                    configurationManager.isConfigEnabled = false
                    waitUntil(timeout: 1) { done in
                        configurationManager.fetchCalledClosure = {
                            expect(RInAppMessaging.initializedModule).toNot(beNil())
                            done()
                        }
                        RInAppMessaging.configure(dependencyManager: dependencyManager)
                    }

                    expect(RInAppMessaging.initializedModule).toEventually(beNil())
                }

                it("will not call ping") {
                    configurationManager.isConfigEnabled = false
                    RInAppMessaging.configure(dependencyManager: dependencyManager)

                    expect(mockMessageMixer.wasPingCalled).toEventuallyNot(equal(true))
                }
            }

            context("when configuration returned true") {

                it("will call ping") {
                    configurationManager.isConfigEnabled = true
                    RInAppMessaging.configure(dependencyManager: dependencyManager)

                    expect(mockMessageMixer.wasPingCalled).toEventually(equal(true))
                }
            }
        }
    }
}

private class ConfigurationManagerMock: ConfigurationManagerType {
    weak var errorDelegate: ErrorDelegate?
    var isConfigEnabled = true
    var fetchCalledClosure = {}

    func fetchAndSaveConfigData(completion: @escaping (ConfigData) -> Void) {
        fetchCalledClosure()
        let emptyURL = URL(string: "about:blank")!
        let emptyEndpoints = EndpointURL(ping: emptyURL,
                                         displayPermission: emptyURL,
                                         impression: emptyURL)
        completion(ConfigData(enabled: isConfigEnabled, endpoints: emptyEndpoints))
    }
}

private class MessageMixerMock: MessageMixerServiceType {
    var wasPingCalled = false

    func ping() -> Result<PingResponse, MessageMixerServiceError> {
        self.wasPingCalled = true
        return .failure(.invalidConfiguration)
    }
}
