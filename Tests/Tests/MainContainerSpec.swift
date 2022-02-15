import Quick
import Nimble
#if canImport(RSDKUtilsMain)
import RSDKUtilsMain // SPM version
#else
import RSDKUtils
#endif
@testable import RInAppMessaging

class MainContainerSpec: QuickSpec {

    override func spec() {
        context("Main Container") {

            var dependencyManager: TypedDependencyManager!

            beforeEach {
                dependencyManager = TypedDependencyManager()
                dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager))
            }

            it("will have all dependencies resolved") {
                let instances: [Any?] = [
                    dependencyManager.resolve(type: CommonUtility.self),
                    dependencyManager.resolve(type: ConfigurationServiceType.self),
                    dependencyManager.resolve(type: ConfigurationRepositoryType.self),
                    dependencyManager.resolve(type: ConfigurationManagerType.self),
                    dependencyManager.resolve(type: CampaignRepositoryType.self),
                    dependencyManager.resolve(type: EventMatcherType.self),
                    dependencyManager.resolve(type: CampaignDispatcherType.self),
                    dependencyManager.resolve(type: AccountRepositoryType.self),
                    dependencyManager.resolve(type: DisplayPermissionServiceType.self),
                    dependencyManager.resolve(type: RouterType.self),
                    dependencyManager.resolve(type: MessageMixerServiceType.self),
                    dependencyManager.resolve(type: ImpressionServiceType.self),
                    dependencyManager.resolve(type: CampaignsValidatorType.self),
                    dependencyManager.resolve(type: ReachabilityType.self),
                    dependencyManager.resolve(type: FullViewPresenterType.self),
                    dependencyManager.resolve(type: SlideUpViewPresenterType.self),
                    dependencyManager.resolve(type: CampaignsListManagerType.self),
                    dependencyManager.resolve(type: CampaignTriggerAgentType.self),
                    dependencyManager.resolve(type: UserDataCacheable.self),
                    dependencyManager.resolve(type: ViewListenerType.self),
                    dependencyManager.resolve(type: TooltipDispatcherType.self),
                    dependencyManager.resolve(type: TooltipManagerType.self),
                    dependencyManager.resolve(type: TooltipPresenterType.self)
                ]
                expect(instances).to(allPass({ $0 != nil }))
                // this test will fail if there are any cycle references
            }
        }
    }
}
