import Quick
import Nimble
@testable import RInAppMessaging

class RouterTests: QuickSpec {

    override func spec() {

        describe("Router") {

            var router: Router!

            func mockContainer() -> DependencyManager.Container {
                return DependencyManager.Container([
                    DependencyManager.ContainerElement(type: ConfigurationManagerType.self, factory: {
                        return ConfigurationManagerMock()
                    }),
                    DependencyManager.ContainerElement(type: CampaignsListManagerType.self, factory: {
                        return CampaignsListManagerMock()
                    })
                ])
            }

            beforeEach {
                let dependencyManager = DependencyManager()
                dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager))
                dependencyManager.appendContainer(mockContainer())
                router = Router(dependencyManager: dependencyManager)
            }

            afterEach {
                UIApplication.shared.keyWindow?.subviews
                    .filter { $0 is BaseView }
                    .forEach { $0.removeFromSuperview() }
            }

            context("when calling displayCampaign") {
                context("and display is not confirmed") {

                    it("will not show campaign message") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, confirmation: { false }, completion: {})
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toAfterTimeout(allPass({ !($0 is BaseView )}))
                    }
                }

                context("and display is confirmed") {

                    it("will show ModalView for modal campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, confirmation: { true }, completion: {})
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toEventually(containElementSatisfying({ $0 is ModalView }))
                    }

                    it("will show FullScreenView for full campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .full)
                        router.displayCampaign(campaign, confirmation: { true }, completion: {})
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toEventually(containElementSatisfying({ $0 is FullScreenView }))
                    }

                    it("will show SlideUpView for slide campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .slide)
                        router.displayCampaign(campaign, confirmation: { true }, completion: {})
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toEventually(containElementSatisfying({ $0 is SlideUpView }))
                    }

                    it("will not show any view for invalid campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .invalid)
                        router.displayCampaign(campaign, confirmation: { true }, completion: {})
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toAfterTimeout(allPass({ !($0 is BaseView )}))
                    }

                    it("will not show any view for html campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .html)
                        router.displayCampaign(campaign, confirmation: { true }, completion: {})
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toAfterTimeout(allPass({ !($0 is BaseView )}))
                    }
                }
            }
        }
    }
}
