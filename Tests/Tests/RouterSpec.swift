import Quick
import Nimble
import UIKit
#if canImport(RSDKUtils)
import class RSDKUtils.TypedDependencyManager
#else // SPM version
import RSDKUtilsNimble
import class RSDKUtilsMain.TypedDependencyManager
#endif
@testable import RInAppMessaging
@testable import NIO

@available(iOS 13.0, *) // because of UIImage(systemName:)
class RouterSpec: QuickSpec {

    override func spec() {

        describe("Router") {

            let window = UIApplication.shared.getKeyWindow()!

            var router: Router!
            var errorDelegate: ErrorDelegateMock!

            func mockContainer() -> TypedDependencyManager.Container {
                return TypedDependencyManager.Container([
                    TypedDependencyManager.ContainerElement(type: ConfigurationManagerType.self, factory: {
                        return ConfigurationManagerMock()
                    }),
                    TypedDependencyManager.ContainerElement(type: CampaignsListManagerType.self, factory: {
                        return CampaignsListManagerMock()
                    })
                ])
            }

            beforeEach {
                errorDelegate = ErrorDelegateMock()
                let dependencyManager = TypedDependencyManager()
                dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager))
                dependencyManager.appendContainer(mockContainer())
                router = Router(dependencyManager: dependencyManager, viewListener: ViewListenerMock())
                router.errorDelegate = errorDelegate
            }

            afterEach {
                window.findIAMView()?.removeFromSuperview()
            }

            context("when calling displayCampaign") {
                context("and display is not confirmed") {

                    it("will not show campaign message") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: false, completion: { _ in })
                        expect(window.findIAMView()).toAfterTimeout(beNil())
                    }
                }

                context("and display is confirmed") {

                    it("will show ModalView for modal campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(window.subviews)
                            .toEventually(containElementSatisfying({ $0 is ModalView }))
                    }

                    it("will show FullScreenView for full campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .full)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(window.subviews)
                            .toEventually(containElementSatisfying({ $0 is FullScreenView }))
                    }

                    it("will show SlideUpView for slide campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .slide)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(window.subviews)
                            .toEventually(containElementSatisfying({ $0 is SlideUpView }))
                    }

                    it("will not show any view for invalid campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .invalid)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(window.subviews)
                            .toAfterTimeout(allPass({ !($0 is BaseView )}))
                    }

                    it("will not show any view for html campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .html)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(window.subviews)
                            .toAfterTimeout(allPass({ !($0 is BaseView )}))
                    }

                    it("will not show any view when another one is still displayed") {
                        let campaign1 = TestHelpers.generateCampaign(id: "test", type: .modal)
                        let campaign2 = TestHelpers.generateCampaign(id: "test", type: .full)
                        router.displayCampaign(campaign1, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(window.subviews)
                            .toEventually(containElementSatisfying({ $0 is ModalView })) // wait
                        router.displayCampaign(campaign2, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(window.subviews)
                            .toAfterTimeoutNot(containElementSatisfying({ $0 is FullScreenView }))
                        expect(window.subviews)
                            .to(containElementSatisfying({ $0 is ModalView }))
                    }

                    it("will add a view to the UIWindow's view when `accessibilityCompatible` is false") {
                        router.accessibilityCompatibleDisplay = false
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(window.subviews).toEventually(containElementSatisfying({ $0 is BaseView }))
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
                    expect(window.subviews)
                        .toEventually(containElementSatisfying({ $0 is BaseView }))
                    router.discardDisplayedCampaign()
                    expect(window.subviews)
                        .toEventuallyNot(containElementSatisfying({ $0 is BaseView }))
                }

                it("will call onDismiss/completion callback with cancelled flag") {
                    let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                    var completionCalled = false
                    router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { cancelled in
                        completionCalled = true
                        expect(cancelled).to(beTrue())
                    })
                    expect(window.subviews)
                        .toEventually(containElementSatisfying({ $0 is BaseView }))
                    router.discardDisplayedCampaign()
                    expect(completionCalled).toEventually(beTrue())
                }
            }

            context("when calling displayTooltip") {

                let targetView: UIView = {
                    let view = UIView()
                    view.accessibilityIdentifier = TooltipViewIdentifierMock
                    return view
                }()
                let tooltip = TestHelpers.generateTooltip(id: "test")
                let imageData = UIImage(systemName: "heart.circle")!.pngData()!

                beforeEach {
                    window.addSubview(targetView)
                }

                afterEach {
                    window.findTooltipView()?.removeFromSuperview()
                    targetView.removeFromSuperview()
                }

                it("will display a tooltip if all data is valid") {
                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: imageData,
                                          becameVisibleHandler: { _ in },
                                          completion: { })
                    expect(window.findTooltipView()).toEventuallyNot(beNil())
                }

                it("will call completion when tooltip was closed") {
                    var completionCalled = false
                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: imageData,
                                          becameVisibleHandler: { _ in },
                                          completion: {
                        completionCalled = true
                    })
                    expect(window.findTooltipView()).toEventuallyNot(beNil())
                    let displayedTooltip = window.findTooltipView()
                    displayedTooltip?.presenter.didTapExitButton()
                    expect(completionCalled).toEventually(beTrue())
                }

                it("will not call completion if the tooltip was removed") {
                    var completionCalled = false
                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: imageData,
                                          becameVisibleHandler: { _ in },
                                          completion: {
                        completionCalled = true
                    })
                    expect(window.findTooltipView()).toEventuallyNot(beNil())
                    let displayedTooltip = window.findTooltipView()!
                    displayedTooltip.removeFromSuperview()
                    expect(completionCalled).toAfterTimeout(beFalse())
                }

                it("will remove existing tooltip with the same target view") {
                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: imageData,
                                          becameVisibleHandler: { _ in },
                                          completion: { })
                    expect(window.findTooltipView()).toEventuallyNot(beNil())
                    let displayedTooltip = window.findTooltipView()
                    expect(displayedTooltip?.superview).toNot(beNil())

                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: imageData,
                                          becameVisibleHandler: { _ in },
                                          completion: { })
                    expect(displayedTooltip?.superview).toEventually(beNil())
                }

                it("will not display a tooltip if identifier does not match") {
                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: "invalid.id",
                                          imageBlob: "image".data(using: .ascii)!,
                                          becameVisibleHandler: { _ in },
                                          completion: { })
                    expect(window.findTooltipView()).toAfterTimeout(beNil())
                }

                it("will report an error if image data is invalid") {
                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: "image".data(using: .ascii)!,
                                          becameVisibleHandler: { _ in },
                                          completion: { })
                    expect(errorDelegate.wasErrorReceived).toEventually(beTrue())
                }

                it("will not display a tooltip if image data is invalid") {
                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: "image".data(using: .ascii)!,
                                          becameVisibleHandler: { _ in },
                                          completion: { })
                    expect(window.findTooltipView()).toAfterTimeout(beNil())
                }

                it("will report an error if targetView has no superview") {
                    targetView.removeFromSuperview()
                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: imageData,
                                          becameVisibleHandler: { _ in },
                                          completion: { })
                    expect(errorDelegate.wasErrorReceived).toEventually(beTrue())
                }

                it("will not display a toolti if targetView has no superview") {
                    targetView.removeFromSuperview()
                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: imageData,
                                          becameVisibleHandler: { _ in },
                                          completion: { })
                    expect(window.findTooltipView()).toAfterTimeout(beNil())
                }

                it("will insert a tooltip in the same UIScrollView type view as the targetView") {
                    let scrollView = UIScrollViewSubclass()
                    scrollView.addSubview(targetView)
                    window.addSubview(scrollView)
                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: imageData,
                                          becameVisibleHandler: { _ in },
                                          completion: { })
                    expect(window.findTooltipView()).toEventuallyNot(beNil())
                    let displayedTooltip = window.findTooltipView()
                    expect(displayedTooltip?.superview).to(beIdenticalTo(scrollView))

                    scrollView.removeFromSuperview()
                }

                it("will insert a tooltip below existing campaign view") {
                    let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                    router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })

                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: imageData,
                                          becameVisibleHandler: { _ in },
                                          completion: { })
                    expect(window.findTooltipView()).toEventuallyNot(beNil())
                    expect(window.findIAMView()).toEventuallyNot(beNil())
                    let displayedTooltip = window.findTooltipView()!
                    let displayedCampaign = window.findIAMView()!

                    expect(displayedTooltip.superview).to(beIdenticalTo(displayedCampaign.superview))
                    let tooltipIndex = displayedTooltip.superview?.subviews.firstIndex(of: displayedTooltip)
                    let campaignIndex = displayedTooltip.superview?.subviews.firstIndex(of: displayedCampaign)
                    expect(campaignIndex).to(beGreaterThan(tooltipIndex))
                }

                it("will update tooltip's position if target view's frame has changed") {
                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: imageData,
                                          becameVisibleHandler: { _ in },
                                          completion: { })
                    expect(window.findTooltipView()).toEventuallyNot(beNil())
                    let displayedTooltip = window.findTooltipView()!
                    let lastTooltipPosition = displayedTooltip.frame.origin
                    let translation = CGAffineTransform(translationX: 40, y: 40)
                    targetView.frame.origin = targetView.frame.origin.applying(translation)

                    expect(displayedTooltip.frame.origin).toEventually(equal(lastTooltipPosition.applying(translation)))
                }

                // To be confirmed
//                it("will remove the tooltip if targeted view changes its identifier") {
//                    router.displayTooltip(tooltip,
//                                          targetView: targetView,
//                                          identifier: TooltipViewIdentifierMock,
//                                          imageBlob: imageData,
//                                          becameVisibleHandler: { _ in },
//                                          completion: { })
//                    expect(window.findTooltipView()).toEventuallyNot(beNil())
//                    let displayedTooltip = window.findTooltipView()!
//                    router.viewDidUpdateIdentifier(from: TooltipViewIdentifierMock, to: "another.identifier", view: targetView)
//                    expect(displayedTooltip.superview).toEventually(beNil())
//                }
//
//                it("will remove the tooltip if targeted view changes its identifier to nil") {
//                    router.displayTooltip(tooltip,
//                                          targetView: targetView,
//                                          identifier: TooltipViewIdentifierMock,
//                                          imageBlob: imageData,
//                                          becameVisibleHandler: { _ in },
//                                          completion: { })
//                    expect(window.findTooltipView()).toEventuallyNot(beNil())
//                    let displayedTooltip = window.findTooltipView()!
//                    router.viewDidUpdateIdentifier(from: TooltipViewIdentifierMock, to: nil, view: targetView)
//                    expect(displayedTooltip.superview).toEventually(beNil())
//                }

                it("will remove the tooltip if targeted view gets removed from superview") {
                    router.displayTooltip(tooltip,
                                          targetView: targetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: imageData,
                                          becameVisibleHandler: { _ in },
                                          completion: { })
                    expect(window.findTooltipView()).toEventuallyNot(beNil())
                    let displayedTooltip = window.findTooltipView()!
                    router.viewDidGetRemovedFromSuperview(targetView, identifier: TooltipViewIdentifierMock)
                    expect(displayedTooltip.superview).toEventually(beNil())
                }
            }
        }
    }
}

private final class UIScrollViewSubclass: UIScrollView { }
