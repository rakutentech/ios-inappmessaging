import Quick
import Nimble
import Foundation

#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsMain
#endif

@testable import RInAppMessaging

class MainContainerSpec: QuickSpec {

    override func spec() {
        context("Main Container") {

            func getRequiredInstances(_ dependencyManager: TypedDependencyManager) -> [Any?] {
                [
                    dependencyManager.resolve(type: CommonUtility.self),
                    dependencyManager.resolve(type: ConfigurationRepositoryType.self),
                    dependencyManager.resolve(type: ConfigurationManagerType.self),
                    dependencyManager.resolve(type: UserDataCacheable.self),
                    dependencyManager.resolve(type: CampaignRepositoryType.self),
                    dependencyManager.resolve(type: EventMatcherType.self),
                    dependencyManager.resolve(type: AccountRepositoryType.self),
                    dependencyManager.resolve(type: ConfigurationServiceType.self),
                    dependencyManager.resolve(type: DisplayPermissionServiceType.self),
                    dependencyManager.resolve(type: RouterType.self),
                    dependencyManager.resolve(type: Randomizer.self),
                    dependencyManager.resolve(type: CampaignDispatcherType.self),
                    dependencyManager.resolve(type: MessageMixerServiceType.self),
                    dependencyManager.resolve(type: ImpressionServiceType.self),
                    dependencyManager.resolve(type: CampaignsListManagerType.self),
                    dependencyManager.resolve(type: CampaignsValidatorType.self),
                    dependencyManager.resolve(type: FullViewPresenterType.self),
                    dependencyManager.resolve(type: SlideUpViewPresenterType.self),
                    dependencyManager.resolve(type: CampaignTriggerAgentType.self),
                    dependencyManager.resolve(type: UserDataCacheable.self),
                    dependencyManager.resolve(type: ViewListenerType.self),
                    dependencyManager.resolve(type: TooltipDispatcherType.self),
                    dependencyManager.resolve(type: TooltipManagerType.self),
                    dependencyManager.resolve(type: TooltipPresenterType.self)
                ]
            }

            var dependencyManager: TypedDependencyManager!

            beforeEach {
                dependencyManager = TypedDependencyManager()
            }

            context("when a valid configURL is provided") {
                beforeEach {
                    dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager,
                                                                                  configURL: URL(string: "http://config.url")!))
                }

                it("will have all dependencies resolved") {
                    let instances = getRequiredInstances(dependencyManager) + [dependencyManager.resolve(type: ReachabilityType.self)]
                    expect(instances).to(allPass({ $0 != nil }))
                    // this test will fail if there are any cycle references
                }
            }

            context("when ReachabilityType dependency is nil") {
                beforeEach {
                    dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager,
                                                                                  configURL: URL(string: "config.url")!))
                    dependencyManager.appendContainer(TypedDependencyManager.Container([
                        // original ReachabilityType container throws an assertion which prevents further testing
                        TypedDependencyManager.ContainerElement(type: ReachabilityType.self, factory: { nil })
                    ]))
                }

                it("will have all required dependencies resolved") {
                    let instances = getRequiredInstances(dependencyManager)
                    expect(instances).to(allPass({ $0 != nil }))
                }
            }
        }
    }
}
