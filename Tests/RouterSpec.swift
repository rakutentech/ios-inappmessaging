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
                UIApplication.shared.getKeyWindow()?.findIAMViewSubview()?.removeFromSuperview()
            }

            context("when calling displayCampaign") {
                context("and display is not confirmed") {

                    it("will not show campaign message") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: false, completion: { _ in })
                        expect(UIApplication.shared.getKeyWindow()?.findIAMViewSubview()).toAfterTimeout(beNil())
                    }
                }

                context("and display is confirmed") {

                    it("will show ModalView for modal campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.getKeyWindow()?.subviews)
                            .toEventually(containElementSatisfying({ $0 is ModalView }))
                    }

                    it("will show FullScreenView for full campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .full)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.getKeyWindow()?.subviews)
                            .toEventually(containElementSatisfying({ $0 is FullScreenView }))
                    }

                    it("will show SlideUpView for slide campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .slide)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.getKeyWindow()?.subviews)
                            .toEventually(containElementSatisfying({ $0 is SlideUpView }))
                    }

                    it("will not show any view for invalid campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .invalid)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.getKeyWindow()?.subviews)
                            .toAfterTimeout(allPass({ !($0 is BaseView )}))
                    }

                    it("will not show any view for html campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .html)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.getKeyWindow()?.subviews)
                            .toAfterTimeout(allPass({ !($0 is BaseView )}))
                    }

                    it("will not show any view when another one is still displayed") {
                        let campaign1 = TestHelpers.generateCampaign(id: "test", type: .modal)
                        let campaign2 = TestHelpers.generateCampaign(id: "test", type: .full)
                        router.displayCampaign(campaign1, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.getKeyWindow()?.subviews)
                            .toEventually(containElementSatisfying({ $0 is ModalView })) // wait
                        router.displayCampaign(campaign2, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.getKeyWindow()?.subviews)
                            .toAfterTimeoutNot(containElementSatisfying({ $0 is FullScreenView }))
                        expect(UIApplication.shared.getKeyWindow()?.subviews)
                            .to(containElementSatisfying({ $0 is ModalView }))
                    }

                    it("will add a view to the UIWindow's view when `accessibilityCompatible` is false") {
                        router.accessibilityCompatibleDisplay = false
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(UIApplication.shared.getKeyWindow()?.subviews).toEventually(containElementSatisfying({ $0 is BaseView }))
                    }

                    it("will add a view to the UIWindow's view main subview when `accessibilityCompatible` is true") {
                        router.accessibilityCompatibleDisplay = true
                        let rootView = UIView()
                        UIApplication.shared.keyWindow?.addSubview(rootView)

                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(rootView.subviews).toEventually(containElementSatisfying({ $0 is BaseView }))
                        rootView.removeFromSuperview()
                    }
                }
            }

            context("when calling discardDisplayedCampaign") {

                it("will remove displayed campaign view") {
                    let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                    router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                    expect(UIApplication.shared.getKeyWindow()?.subviews)
                        .toEventually(containElementSatisfying({ $0 is BaseView }))
                    router.discardDisplayedCampaign()
                    expect(UIApplication.shared.getKeyWindow()?.subviews)
                        .toEventuallyNot(containElementSatisfying({ $0 is BaseView }))
                }

                it("will call onDismiss/completion callback with cancelled flag") {
                    let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                    var completionCalled = false
                    router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { cancelled in
                        completionCalled = true
                        expect(cancelled).to(beTrue())
                    })
                    expect(UIApplication.shared.getKeyWindow()?.subviews)
                        .toEventually(containElementSatisfying({ $0 is BaseView }))
                    router.discardDisplayedCampaign()
                    expect(completionCalled).toEventually(beTrue())
                }
            }
        }
    }
}
