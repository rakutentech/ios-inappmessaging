import Quick
import Nimble
@testable import RInAppMessaging

class MainContainerTests: QuickSpec {

    override func spec() {
        context("Main Container") {

            var dependencyManager: DependencyManager!

            beforeEach {
                dependencyManager = DependencyManager()
                dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager))
            }

            it("will have all dependencies resolved") {
                let instances: [Any?] = [
                    dependencyManager.resolve(type: CommonUtility.self),
                    dependencyManager.resolve(type: ConfigurationClient.self),
                    dependencyManager.resolve(type: CampaignRepositoryType.self),
                    dependencyManager.resolve(type: EventMatcherType.self),
                    dependencyManager.resolve(type: ReadyCampaignDispatcherType.self),
                    dependencyManager.resolve(type: IAMPreferenceRepository.self),
                    dependencyManager.resolve(type: PermissionClientType.self),
                    dependencyManager.resolve(type: RouterType.self),
                    dependencyManager.resolve(type: MessageMixerClientType.self),
                    dependencyManager.resolve(type: ImpressionClientType.self),
                    dependencyManager.resolve(type: CampaignsValidatorType.self),
                    dependencyManager.resolve(type: ReachabilityType.self),
                    dependencyManager.resolve(type: FullViewPresenter.self),
                    dependencyManager.resolve(type: SlideUpViewPresenter.self)
                ]
                expect(instances).to(allPass({ $0 != nil }))
            }
        }
    }
}
