import Quick
import Nimble
import Foundation

#if canImport(RSDKUtilsMain)
import class RSDKUtilsMain.TypedDependencyManager // SPM version
#else
import class RSDKUtils.TypedDependencyManager
#endif

@testable import RInAppMessaging

/// Tests for behavior of the SDK when supplied with different configuration responses.
class ConfigurationSpec: QuickSpec {

    override func spec() {
        context("InAppMessaging") {

            var configurationManager: ConfigurationManagerMock!
            var mockMessageMixer: MessageMixerServiceMock!
            var dependencyManager: TypedDependencyManager!

            func mockContainer() -> TypedDependencyManager.Container {
                return TypedDependencyManager.Container([
                    TypedDependencyManager.ContainerElement(type: ConfigurationManagerType.self, factory: {
                        return configurationManager
                    }),
                    TypedDependencyManager.ContainerElement(type: MessageMixerServiceType.self, factory: {
                        return mockMessageMixer
                    })
                ])
            }

            beforeEach {
                mockMessageMixer = MessageMixerServiceMock()
                dependencyManager = TypedDependencyManager()
                configurationManager = ConfigurationManagerMock()
                RInAppMessaging.deinitializeModule()
                dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager,
                                                                              configURL: URL(string: "config.url")!))
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
                        RInAppMessaging.configure(dependencyManager: dependencyManager,
                                                  moduleConfig: InAppMessagingModuleConfiguration.empty)
                    }

                    expect(RInAppMessaging.initializedModule).toEventually(beNil())
                    expect(RInAppMessaging.dependencyManager).toEventually(beNil())
                }

                it("will not call ping") {
                    RInAppMessaging.configure(dependencyManager: dependencyManager,
                                              moduleConfig: InAppMessagingModuleConfiguration.empty)

                    expect(mockMessageMixer.wasPingCalled).toAfterTimeout(beFalse())
                }
            }

            context("when configuration returned true") {

                it("will call ping") {
                    configurationManager.rolloutPercentage = 100
                    RInAppMessaging.configure(dependencyManager: dependencyManager,
                                              moduleConfig: InAppMessagingModuleConfiguration.empty)

                    expect(mockMessageMixer.wasPingCalled).toEventually(beTrue())
                }
            }
        }
    }
}
