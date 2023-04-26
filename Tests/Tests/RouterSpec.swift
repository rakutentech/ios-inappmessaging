import Quick
import Nimble
import UIKit

#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsNimble
import class RSDKUtilsMain.TypedDependencyManager
#endif

@testable import RInAppMessaging

@available(iOS 13.0, *) // Because of UIImage(named:in:with:)
class RouterSpec: QuickSpec {
// swiftlint:disable:previous type_body_length

    // swiftlint:disable:next function_body_length
    override func spec() {

        describe("Router") {

            let window = UIApplication.shared.getKeyWindow()!

            var router: Router!
            var errorDelegate: ErrorDelegateMock!

            func mockContainer() -> TypedDependencyManager.Container {
                TypedDependencyManager.Container([
                    TypedDependencyManager.ContainerElement(type: ConfigurationManagerType.self, factory: {
                        ConfigurationManagerMock()
                    }),
                    TypedDependencyManager.ContainerElement(type: CampaignsListManagerType.self, factory: {
                        CampaignsListManagerMock()
                    })
                ])
            }

            beforeEach {
                errorDelegate = ErrorDelegateMock()
                let dependencyManager = TypedDependencyManager()
                dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager,
                                                                              configURL: URL(string: "config.url")!))
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
                        expect(window.findIAMView()).toAfterTimeout(beNil())
                    }

                    it("will not show any view for html campaign type") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .html)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(window.findIAMView()).toAfterTimeout(beNil())
                    }

                    it("will not show another view when one is already displayed") {
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
                        expect(window.findIAMView()).toEventuallyNot(beNil())
                    }

                    it("will add a view to the UIWindow's view main subview when `accessibilityCompatible` is true") {
                        router.accessibilityCompatibleDisplay = true
                        let rootView = UIView()
                        UIApplication.shared.keyWindow?.addSubview(rootView)

                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(rootView.findIAMView()).toEventuallyNot(beNil())
                        rootView.removeFromSuperview()
                    }
                }
            }

            context("when calling discardDisplayedCampaign") {

                it("will remove displayed campaign view") {
                    let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                    router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })

                    expect(window.findIAMView()).toEventuallyNot(beNil())
                    router.discardDisplayedCampaign()
                    expect(window.findIAMView()).toEventually(beNil())
                }

                it("will not remove the campaign that doesn't exist") {
                    router.discardDisplayedCampaign()
                    expect(window.findIAMView()).toEventually(beNil())
                }

                it("will call onDismiss/completion callback with cancelled flag") {
                    let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                    var completionCalled = false
                    router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { cancelled in
                        completionCalled = true
                        expect(cancelled).to(beTrue())
                    })

                    expect(window.findIAMView()).toEventuallyNot(beNil())
                    router.discardDisplayedCampaign()
                    expect(completionCalled).toEventually(beTrue())
                }
            }

            context("when calling discardDisplayedTooltip") {

                let tooltipTargetView = UIView(frame: CGRect(x: 100, y: 100, width: 10, height: 10))
                let tooltip = TestHelpers.generateTooltip(id: "test")
                let imageBlob: Data! = UIImage(named: "test-image", in: .unitTests, with: nil)?.pngData()

                beforeEach {
                    tooltipTargetView.accessibilityIdentifier = TooltipViewIdentifierMock
                    window.addSubview(tooltipTargetView)
                }

                afterEach {
                    tooltipTargetView.removeFromSuperview()
                    window.findTooltipView()?.removeFromSuperview()
                }

                context("with matching identifier") {
                    it("will remove displayed tooltp") {
                        router.displayTooltip(tooltip, targetView: tooltipTargetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })

                        expect(window.findTooltipView()).toEventuallyNot(beNil())
                        router.discardDisplayedTooltip(with: TooltipViewIdentifierMock)
                        expect(window.findTooltipView()).toEventually(beNil())
                    }

                    it("will call onDismiss/completion callback with cancelled flag") {
                        var completionCalled = false
                        router.displayTooltip(tooltip, targetView: tooltipTargetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { cancelled in
                            expect(cancelled).to(beTrue())
                            completionCalled = true
                        })

                        expect(window.findTooltipView()).toEventuallyNot(beNil())
                        router.discardDisplayedTooltip(with: TooltipViewIdentifierMock)
                        expect(completionCalled).toEventually(beTrue())
                    }
                }

                context("and identifier does not match") {
                    it("will not remove displayed tooltip") {
                        router.displayTooltip(tooltip, targetView: tooltipTargetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })

                        expect(window.findTooltipView()).toEventuallyNot(beNil())
                        router.discardDisplayedTooltip(with: "other-id")
                        expect(window.findTooltipView()).toAfterTimeoutNot(beNil())
                    }
                }
            }

            context("when calling isDisplayingTooltip") {

                let tooltipTargetView = UIView(frame: CGRect(x: 100, y: 100, width: 10, height: 10))
                let tooltip = TestHelpers.generateTooltip(id: "test")
                let imageBlob: Data! = UIImage(named: "test-image", in: .unitTests, with: nil)?.pngData()

                beforeEach {
                    tooltipTargetView.accessibilityIdentifier = TooltipViewIdentifierMock
                    window.addSubview(tooltipTargetView)
                }

                afterEach {
                    tooltipTargetView.removeFromSuperview()
                    window.findTooltipView()?.removeFromSuperview()
                }

                it("will return true when tooltip displayed") {
                    router.displayTooltip(tooltip, targetView: tooltipTargetView,
                                          identifier: TooltipViewIdentifierMock,
                                          imageBlob: imageBlob,
                                          becameVisibleHandler: { _ in },
                                          confirmation: true,
                                          completion: { _ in })
                    expect(window.findTooltipView()).toEventuallyNot(beNil())
                    expect(router.isDisplayingTooltip(with: TooltipViewIdentifierMock)).to(beTrue())
                }

                it("will return false when tooltip is not displayed") {
                    expect(router.isDisplayingTooltip(with: "test")).to(beFalse())
                }

                it("will return a value when calling the function from main thread") {
                    let q = DispatchQueue(label: "test")
                    q.async {
                        expect(router.isDisplayingTooltip(with: "test")).to(beFalse())
                    }
                }
            }

            context("when calling displayTooltip") {

                let targetView: UIView = {
                    let view = UIView()
                    view.accessibilityIdentifier = TooltipViewIdentifierMock
                    return view
                }()
                let tooltip = TestHelpers.generateTooltip(id: "test")
                let imageBlob: Data! = UIImage(named: "test-image", in: .unitTests, with: nil)?.pngData()

                beforeEach {
                    window.addSubview(targetView)
                }

                afterEach {
                    window.findTooltipView()?.removeFromSuperview()
                    targetView.removeFromSuperview()
                }

                context("and display is not confirmed") {

                    it("will not display a tooltip") {
                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: false,
                                              completion: { _ in })
                        expect(window.findTooltipView()).toAfterTimeout(beNil())
                    }

                    it("will call completion with true flag when tooltip was closed") {
                        waitUntil { done in
                            router.displayTooltip(tooltip,
                                                  targetView: targetView,
                                                  identifier: TooltipViewIdentifierMock,
                                                  imageBlob: imageBlob,
                                                  becameVisibleHandler: { _ in },
                                                  confirmation: false,
                                                  completion: { cancelled in

                                expect(cancelled).to(beTrue())
                                done()
                            })
                        }
                    }
                }

                context("and display is confirmed") {

                    it("will display a tooltip if all data is valid") {
                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(window.findTooltipView()).toEventuallyNot(beNil())
                    }

                    it("will display a tooltip above the campaign view") {
                        let rootView = UIView()
                        UIApplication.shared.keyWindow?.addSubview(rootView)
                        router.accessibilityCompatibleDisplay = true
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })
                        expect(window.findIAMView()).toEventuallyNot(beNil())

                        router.displayTooltip(tooltip,
                                              targetView: rootView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(window.findTooltipView()).toEventuallyNot(beNil())
                        rootView.findIAMView()?.removeFromSuperview()
                    }

                    it("will not display a tooltip campaign with no tooltip data") {
                        let tooltip = TestHelpers.generateTooltip(id: "test", isTooltip: false)
                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(window.findTooltipView()).toEventually(beNil())
                    }

                    it("will call completion with false flag when tooltip was closed") {
                        var completionCalled = false
                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { cancelled in
                            expect(cancelled).to(beFalse())
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
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in
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
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(window.findTooltipView()).toEventuallyNot(beNil())
                        let displayedTooltip = window.findTooltipView()
                        expect(displayedTooltip?.superview).toNot(beNil())

                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(displayedTooltip?.superview).toEventually(beNil())
                    }

                    it("will not display a tooltip if identifier does not match") {
                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: "invalid.id",
                                              imageBlob: "image".data(using: .ascii)!,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(window.findTooltipView()).toAfterTimeout(beNil())
                    }

                    it("will report an error if image data is invalid") {
                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: "image".data(using: .ascii)!,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(errorDelegate.wasErrorReceived).toEventually(beTrue())
                    }

                    it("will not display a tooltip if image data is invalid") {
                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: "image".data(using: .ascii)!,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(window.findTooltipView()).toAfterTimeout(beNil())
                    }

                    it("will not display a tooltip if the tooltip presenter cannot found") {
                        let router = Router(dependencyManager: TypedDependencyManager(), viewListener: ViewListenerMock())
                        expect(router.displayTooltip(tooltip,
                                                     targetView: targetView,
                                                     identifier: TooltipViewIdentifierMock,
                                                     imageBlob: "image".data(using: .ascii)!,
                                                     becameVisibleHandler: { _ in },
                                                     confirmation: true,
                                                     completion: { _ in })).to(throwAssertion())
                        expect(window.findTooltipView()).toAfterTimeout(beNil())
                    }

                    it("will report an error if targetView has no superview") {
                        targetView.removeFromSuperview()
                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(errorDelegate.wasErrorReceived).toEventually(beTrue())
                    }

                    it("will not display a tooltip if targetView has no superview") {
                        targetView.removeFromSuperview()
                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(window.findTooltipView()).toAfterTimeout(beNil())
                    }

                    it("will insert a tooltip in the same UIScrollView type view as the targetView") {
                        let scrollView = UIScrollViewSubclass()
                        scrollView.addSubview(targetView)
                        window.addSubview(scrollView)
                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(window.findTooltipView()).toEventuallyNot(beNil())
                        let displayedTooltip = window.findTooltipView()
                        expect(displayedTooltip?.superview).to(beIdenticalTo(scrollView))

                        scrollView.removeFromSuperview()
                    }

                    it("will insert a tooltip in the same UIWindow type view as the targetView") {
                        let uiWindow = UIWindowSubclass()
                        uiWindow.addSubview(targetView)
                        window.addSubview(uiWindow)
                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(window.findTooltipView()).toEventuallyNot(beNil())
                        let displayedTooltip = window.findTooltipView()
                        expect(displayedTooltip?.superview).to(beIdenticalTo(uiWindow))

                        uiWindow.removeFromSuperview()
                    }

                    it("will insert a tooltip below existing campaign view") {
                        let campaign = TestHelpers.generateCampaign(id: "test", type: .modal)
                        router.displayCampaign(campaign, associatedImageData: nil, confirmation: true, completion: { _ in })

                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
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
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(window.findTooltipView()).toEventuallyNot(beNil())
                        let displayedTooltip = window.findTooltipView()!
                        let lastTooltipPosition = displayedTooltip.frame.origin
                        let translation = CGAffineTransform(translationX: 40, y: 40)
                        targetView.frame.origin = targetView.frame.origin.applying(translation)

                        expect(displayedTooltip.frame.origin).toEventually(equal(lastTooltipPosition.applying(translation)))
                    }

                    it("will show tooltip's position in the correct position") {
                        func comparePosition(displayedTooltip: TooltipView, targetView: UIView, superView: UIView, position: TooltipBodyData.Position) -> Bool {
                            let targetViewFrame = superView.convert(targetView.frame, from: superView.superview)
                            var targetPosition: CGPoint
                            switch position {
                            case .topCenter:
                                targetPosition = CGPoint(x: targetViewFrame.midX - displayedTooltip.frame.width / 2.0,
                                                         y: targetViewFrame.origin.y -
                                                         displayedTooltip.frame.height -
                                                         Router.UIConstants.Tooltip.targetViewSpacing)
                            case .topLeft:
                                targetPosition = CGPoint(x: targetViewFrame.minX - displayedTooltip.frame.width,
                                                         y: targetViewFrame.origin.y -
                                                         displayedTooltip.frame.height -
                                                         Router.UIConstants.Tooltip.targetViewSpacing)
                            case .topRight:
                                targetPosition = CGPoint(x: targetViewFrame.maxX,
                                                         y: targetViewFrame.origin.y -
                                                         displayedTooltip.frame.height -
                                                         Router.UIConstants.Tooltip.targetViewSpacing)
                            case .bottomLeft:
                                targetPosition = CGPoint(x: targetViewFrame.minX - displayedTooltip.frame.width,
                                                         y: targetViewFrame.maxY +
                                                         Router.UIConstants.Tooltip.targetViewSpacing)
                            case .bottomRight:
                                targetPosition = CGPoint(x: targetViewFrame.maxX,
                                                         y: targetViewFrame.maxY +
                                                         Router.UIConstants.Tooltip.targetViewSpacing)
                            case .bottomCenter:
                                targetPosition = CGPoint(x: targetViewFrame.midX -
                                                         displayedTooltip.frame.width / 2.0,
                                                         y: targetViewFrame.maxY +
                                                         Router.UIConstants.Tooltip.targetViewSpacing)
                            case .left:
                                targetPosition = CGPoint(x: targetViewFrame.minX -
                                                         displayedTooltip.frame.width -
                                                         Router.UIConstants.Tooltip.targetViewSpacing,
                                                         y: targetViewFrame.midY -
                                                         displayedTooltip.frame.height / 2.0)
                            case .right:
                                targetPosition = CGPoint(x: targetViewFrame.maxX +
                                                         Router.UIConstants.Tooltip.targetViewSpacing,
                                                         y: targetViewFrame.midY -
                                                         displayedTooltip.frame.height / 2.0)
                            }
                            return displayedTooltip.frame.origin.x == targetPosition.x &&
                                   displayedTooltip.frame.origin.y == targetPosition.y
                        }

                        for position in [
                            TooltipBodyData.Position.topLeft,
                            TooltipBodyData.Position.topRight,
                            TooltipBodyData.Position.topCenter,
                            TooltipBodyData.Position.bottomLeft,
                            TooltipBodyData.Position.bottomRight,
                            TooltipBodyData.Position.bottomCenter,
                            TooltipBodyData.Position.left,
                            TooltipBodyData.Position.right
                        ] {
                            let window = UIApplication.shared.getKeyWindow()!
                            let tooltipTargetView = UIView(frame: CGRect(x: 100, y: 100, width: 10, height: 10))
                            window.addSubview(tooltipTargetView)
                            let imageBlob: Data! = UIImage(named: "test-image", in: .unitTests, with: nil)?.pngData()
                            let tooltip = TestHelpers.generateTooltip(id: "test", position: position.rawValue)
                            router.displayTooltip(tooltip,
                                                  targetView: tooltipTargetView,
                                                  identifier: TooltipViewIdentifierMock,
                                                  imageBlob: imageBlob,
                                                  becameVisibleHandler: { _ in },
                                                  confirmation: true,
                                                  completion: { _ in })
                            expect(window.findTooltipView()).toEventuallyNot(beNil())
                            let displayedTooltip = window.findTooltipView()!
                            expect(comparePosition(
                                displayedTooltip: displayedTooltip,
                                targetView: tooltipTargetView,
                                superView: window,
                                position: position)).toEventually(beTrue())
                        }
                    }

                    it("will remove the tooltip if targeted view changes its identifier to nil") {
                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(window.findTooltipView()).toEventuallyNot(beNil())
                        let displayedTooltip = window.findTooltipView()!
                        router.viewDidUpdateIdentifier(from: TooltipViewIdentifierMock, to: nil, view: targetView)
                        expect(displayedTooltip.superview).toEventually(beNil())
                    }

                    it("will remove the tooltip if targeted view gets removed from superview") {
                        router.displayTooltip(tooltip,
                                              targetView: targetView,
                                              identifier: TooltipViewIdentifierMock,
                                              imageBlob: imageBlob,
                                              becameVisibleHandler: { _ in },
                                              confirmation: true,
                                              completion: { _ in })
                        expect(window.findTooltipView()).toEventuallyNot(beNil())
                        let displayedTooltip = window.findTooltipView()!
                        router.viewDidGetRemovedFromSuperview(targetView, identifier: TooltipViewIdentifierMock)
                        expect(displayedTooltip.superview).toEventually(beNil())
                    }
                }
            }
        }
    }
}

private final class UIScrollViewSubclass: UIScrollView { }
private final class UIWindowSubclass: UIWindow { }
