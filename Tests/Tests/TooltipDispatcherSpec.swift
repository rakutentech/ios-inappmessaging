import Foundation
import Quick
import Nimble
import UIKit
#if canImport(RSDKUtilsTestHelpers)
import class RSDKUtilsTestHelpers.URLSessionMock // SPM version
#else
import class RSDKUtils.URLSessionMock
#endif
@testable import RInAppMessaging

class TooltipDispatcherSpec: QuickSpec {

    override func spec() {
        describe("TooltipDispatcher") {

            let targetView: UIView = {
                let view = UIView()
                view.accessibilityIdentifier = TooltipViewIdentifierMock
                return view
            }()
            let tooltip = TestHelpers.generateTooltip(id: "test")
            let window = UIApplication.shared.getKeyWindow()!

            var dispatcher: TooltipDispatcher!
            var campaignRepository: CampaignRepositoryMock!
            var router: RouterMock!
            var httpSession: URLSessionMock!
            var viewListener: ViewListenerMock!

            beforeEach {
                campaignRepository = CampaignRepositoryMock()
                router = RouterMock()
                viewListener = ViewListenerMock()
                dispatcher = TooltipDispatcher(router: router,
                                               campaignRepository: campaignRepository,
                                               viewListener: viewListener)

                URLSessionMock.startMockingURLSession()
                httpSession = URLSessionMock.mock(originalInstance: dispatcher.httpSession)

                // simulated success response for imageUrl
                httpSession.httpResponse = HTTPURLResponse(url: URL(string: "https://example.com/cat.jpg")!,
                                                           statusCode: 200,
                                                           httpVersion: nil,
                                                           headerFields: nil)
                httpSession.responseData = Data()
                httpSession.responseError = nil

                window.addSubview(targetView)
                viewListener.displayedViews = [targetView]
            }

            afterEach {
                URLSessionMock.stopMockingURLSession()
                targetView.removeFromSuperview()
            }

            it("won't display a tooltip when it was not marked as needs display even if the target view is present") {
                dispatcher.viewDidMoveToWindow(targetView, identifier: TooltipViewIdentifierMock)
                expect(router.lastDisplayedTooltip).toAfterTimeout(beNil())
            }

            context("when tooltip it is marked as needs display") {
                it("won't display a tooltip when the target view is not present") {
                    viewListener.displayedViews.removeAll()
                    dispatcher.setNeedsDisplay(tooltip: tooltip)
                    expect(router.lastDisplayedTooltip).toAfterTimeout(beNil())
                }

                it("will display a tooltip when the target view is present") {
                    dispatcher.setNeedsDisplay(tooltip: tooltip)
                    expect(router.lastDisplayedTooltip).toEventuallyNot(beNil())
                }

                it("will display a tooltip when presented target view updated its identifier") {
                    targetView.accessibilityIdentifier = nil
                    dispatcher.setNeedsDisplay(tooltip: tooltip)
                    expect(router.lastDisplayedTooltip).toAfterTimeout(beNil())
                    targetView.accessibilityIdentifier = TooltipViewIdentifierMock
                    // this is normally sent by the ViewListener
                    dispatcher.viewDidUpdateIdentifier(from: nil, to: TooltipViewIdentifierMock, view: targetView)
                    expect(router.lastDisplayedTooltip).toEventuallyNot(beNil())
                }
            }

            it("will not display a tooltip when there was an image download error") {
                httpSession.responseError =  HttpRequestableObjectError.sessionError
                dispatcher.setNeedsDisplay(tooltip: tooltip)
                dispatcher.viewDidChangeSuperview(targetView, identifier: TooltipViewIdentifierMock)
                expect(router.lastDisplayedTooltip).toAfterTimeout(beNil())
            }

            context("when tooltip is displayed") {
                beforeEach {
                    let tooltip = TestHelpers.generateTooltip(id: "test", autoCloseSeconds: 10)
                    dispatcher.setNeedsDisplay(tooltip: tooltip)
                    dispatcher.viewDidMoveToWindow(targetView, identifier: TooltipViewIdentifierMock)
                    expect(router.lastDisplayedTooltip).toEventuallyNot(beNil())
                }

                it("will update currently displayed tooltip when the target view changed appeared") {
                    router.lastDisplayedTooltip = nil
                    dispatcher.viewDidMoveToWindow(targetView, identifier: TooltipViewIdentifierMock)
                    expect(router.lastDisplayedTooltip).toEventuallyNot(beNil())
                }

                it("will update currently displayed tooltip when the target view changed its superview") {
                    router.lastDisplayedTooltip = nil
                    dispatcher.viewDidChangeSuperview(targetView, identifier: TooltipViewIdentifierMock)
                    expect(router.lastDisplayedTooltip).toEventuallyNot(beNil())
                }

                it("will not decrement impressionsLeft when before tooltip is closed") {
                    expect(campaignRepository.decrementImpressionsCalls).toAfterTimeout(equal(0))
                }

                it("will start auto-disappear when tooltip becomes visible") {
                    let tooltipView = TooltipViewMock()
                    router.callTooltipBecameVisibleHandler(tooltipView: tooltipView)
                    expect(tooltipView.startedAutoDisappearing).toEventually(beTrue())
                }

                it("will not start auto-disappear if delay is 0") {
                    let anotherTargetView = UIView()
                    anotherTargetView.accessibilityIdentifier = "view.another.id"
                    window.addSubview(anotherTargetView)
                    let anotherTooltip = TestHelpers.generateTooltip(id: "test.auto", targetViewID: "view.another.id", autoCloseSeconds: 0)
                    dispatcher.setNeedsDisplay(tooltip: anotherTooltip)
                    dispatcher.viewDidMoveToWindow(targetView, identifier: "view.another.id")
                    expect(router.lastDisplayedTooltip?.id).toEventually(equal("test.auto"))

                    let tooltipView = TooltipViewMock()
                    router.callTooltipBecameVisibleHandler(tooltipView: tooltipView)
                    expect(tooltipView.startedAutoDisappearing).toAfterTimeout(beFalse())

                    anotherTargetView.removeFromSuperview()
                }
            }

            context("after dispatching") {
                beforeEach {
                    let tooltip = TestHelpers.generateTooltip(id: "test", autoCloseSeconds: 10)
                    dispatcher.setNeedsDisplay(tooltip: tooltip)
                    dispatcher.viewDidMoveToWindow(targetView, identifier: TooltipViewIdentifierMock)
                    expect(router.lastDisplayedTooltip).toEventuallyNot(beNil())
                }

                it("will decrement impressionsLeft") {
                    router.completeDisplayingTooltip(cancelled: false)
                    expect(campaignRepository.decrementImpressionsCalls).to(equal(1))
                }

                it("will not decrement impressionsLeft when display was cancelled") {
                    router.completeDisplayingTooltip(cancelled: true)
                    expect(campaignRepository.decrementImpressionsCalls).toAfterTimeout(equal(0))
                }

                it("will remove the tooltip from queue") {
                    router.completeDisplayingTooltip(cancelled: false)
                    expect(dispatcher.queuedTooltips).toNot(contain(tooltip))
                }
            }
        }
    }
}
