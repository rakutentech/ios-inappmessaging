import Quick
import Nimble
@testable import RInAppMessaging

/// Tests for behavior of the SDK when supplied with different configuration responses.
class ConfigurationSpec: QuickSpec {

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

                beforeEach {
                    configurationManager.rolloutPercentage = 0
                }

                it("will disable module") {
                    waitUntil { done in
                        configurationManager.fetchCalledClosure = {
                            expect(RInAppMessaging.initializedModule).toNot(beNil())
                            done()
                        }
                        RInAppMessaging.configure(dependencyManager: dependencyManager)
                    }

                    expect(RInAppMessaging.initializedModule).toEventually(beNil())
                }

                it("will not call ping") {
                    RInAppMessaging.configure(dependencyManager: dependencyManager)

                    expect(mockMessageMixer.wasPingCalled).toAfterTimeout(beFalse())
                }
            }

            context("when configuration returned true") {

                it("will call ping") {
                    configurationManager.rolloutPercentage = 100
                    RInAppMessaging.configure(dependencyManager: dependencyManager)

                    expect(mockMessageMixer.wasPingCalled).toEventually(beTrue())
                }
            }
        }
    }
}
