import Quick
import Nimble
@testable import RInAppMessaging

class RouterSpec: QuickSpec {

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
                        router.displayCampaign(campaign, confirmation: false, completion: { _ in })
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toAfterTimeout(allPass({ !($0 is BaseView )}))
                    }
                }

                context("and display is confirmed") {

                    it("will show ModalView for modal campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toEventually(containElementSatisfying({ $0 is ModalView }))
                    }

                    it("will show FullScreenView for full campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .full)
                        router.displayCampaign(campaign, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toEventually(containElementSatisfying({ $0 is FullScreenView }))
                    }

                    it("will show SlideUpView for slide campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .slide)
                        router.displayCampaign(campaign, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toEventually(containElementSatisfying({ $0 is SlideUpView }))
                    }

                    it("will not show any view for invalid campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .invalid)
                        router.displayCampaign(campaign, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toAfterTimeout(allPass({ !($0 is BaseView )}))
                    }

                    it("will not show any view for html campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .html)
                        router.displayCampaign(campaign, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toAfterTimeout(allPass({ !($0 is BaseView )}))
                    }

                    it("will not show any view when another one is still displayed") {
                        let campaign1 = TestHelpers.generateCampaign(id: "test", type: .modal)
                        let campaign2 = TestHelpers.generateCampaign(id: "test", type: .full)
                        router.displayCampaign(campaign1, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toEventually(containElementSatisfying({ $0 is ModalView })) // wait
                        router.displayCampaign(campaign2, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .toAfterTimeoutNot(containElementSatisfying({ $0 is FullScreenView }))
                        expect(UIApplication.shared.keyWindow?.subviews)
                            .to(containElementSatisfying({ $0 is ModalView }))
                    }

                    it("will add a view to the UIWindow's view when `accessibilityCompatible` is false") {
                        router.accessibilityCompatibleDisplay = false
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.keyWindow?.subviews).toEventually(containElementSatisfying({ $0 is BaseView }))
                    }

                    it("will add a view to the UIWindow's view main subview when `accessibilityCompatible` is true") {
                        router.accessibilityCompatibleDisplay = true
                        let rootView = UIView()
                        UIApplication.shared.keyWindow?.addSubview(rootView)

                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, confirmation: true, completion: { _ in })
                        expect(rootView.subviews).toEventually(containElementSatisfying({ $0 is BaseView }))
                        rootView.removeFromSuperview()
                    }
                }
            }

            context("when calling displayCampaign") {

                it("will remove displayed campaign view") {
                    let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                    router.displayCampaign(campaign, confirmation: true, completion: { _ in })
                    expect(UIApplication.shared.keyWindow?.subviews)
                        .toEventually(containElementSatisfying({ $0 is BaseView }))
                    router.discardDisplayedCampaign()
                    expect(UIApplication.shared.keyWindow?.subviews)
                        .toEventuallyNot(containElementSatisfying({ $0 is BaseView }))
                }

                it("will not call onDismiss/completion callback") {
                    let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                    var completionCalled = false
                    router.displayCampaign(campaign, confirmation: true, completion: { _ in
                        completionCalled = true
                    })
                    expect(UIApplication.shared.keyWindow?.subviews)
                        .toEventually(containElementSatisfying({ $0 is BaseView }))
                    router.discardDisplayedCampaign()
                    expect(completionCalled).toAfterTimeout(beFalse())
                }
            }
        }
    }
}
