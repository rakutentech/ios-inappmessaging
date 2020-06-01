import Quick
import Nimble
@testable import RInAppMessaging

/// Tests for behavior of the SDK when supplied with different configuration responses.
class ConfigurationTests: QuickSpec {

    override func spec() {
        context("InAppMessaging") {

            var configurationManager: ConfigurationManagerMock!
            var mockMessageMixer: MessageMixerServiceMock!
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
                mockMessageMixer = MessageMixerServiceMock()
                dependencyManager = DependencyManager()
                configurationManager = ConfigurationManagerMock()
                RInAppMessaging.deinitializeModule()
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
