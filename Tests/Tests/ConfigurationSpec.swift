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
            var mockPingService: PingServiceMock!
            var dependencyManager: TypedDependencyManager!

            func mockContainer() -> TypedDependencyManager.Container {
                TypedDependencyManager.Container([
                    TypedDependencyManager.ContainerElement(type: ConfigurationManagerType.self, factory: {
                        configurationManager
                    }),
                    TypedDependencyManager.ContainerElement(type: PingServiceType.self, factory: {
                        mockPingService
                    })
                ])
            }

            beforeEach {
                mockPingService = PingServiceMock()
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
                    waitUntil { done in
                        RInAppMessaging.configure(dependencyManager: dependencyManager,
                                                  moduleConfig: .empty) { shouldDeinit in
                            expect(shouldDeinit).to(beTrue())
                            done()
                        }
                    }
                }

                it("will disable module") {
                    expect(RInAppMessaging.interactor.iamModule).toEventually(beNil())
                    expect(RInAppMessaging.dependencyManager).toEventually(beNil())
                }

                it("will not call ping") {
                    expect(mockPingService.wasPingCalled).toAfterTimeout(beFalse())
                }
            }

            context("when configuration returned true") {

                it("will call ping") {
                    configurationManager.rolloutPercentage = 100
                    waitUntil { done in
                        RInAppMessaging.configure(dependencyManager: dependencyManager,
                                                  moduleConfig: .empty) { shouldDeinit in
                            expect(shouldDeinit).to(beFalse())
                            done()
                        }
                    }

                    expect(mockPingService.wasPingCalled).toEventually(beTrue())
                }
            }
        }
    }
}
