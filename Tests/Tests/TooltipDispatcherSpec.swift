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
                expect(router.displayedTooltips).toAfterTimeout(beEmpty())
            }

            context("when tooltip it is marked as needs display") {
                it("won't display a tooltip when the target view is not present") {
                    viewListener.displayedViews.removeAll()
                    dispatcher.setNeedsDisplay(tooltip: tooltip)
                    expect(router.displayedTooltips).toAfterTimeout(beEmpty())
                }

                it("will display a tooltip when the target view is present") {
                    dispatcher.setNeedsDisplay(tooltip: tooltip)
                    expect(router.displayedTooltips).toEventuallyNot(beEmpty())
                }

                it("will display a tooltip when presented target view updated its identifier") {
                    targetView.accessibilityIdentifier = nil
                    dispatcher.setNeedsDisplay(tooltip: tooltip)
                    expect(router.displayedTooltips).toAfterTimeout(beEmpty())
                    targetView.accessibilityIdentifier = TooltipViewIdentifierMock
                    // this is normally sent by the ViewListener
                    dispatcher.viewDidUpdateIdentifier(from: nil, to: TooltipViewIdentifierMock, view: targetView)
                    expect(router.displayedTooltips).toEventuallyNot(beEmpty())
                }
            }

            it("will not display a tooltip when there was an image download error") {
                httpSession.responseError =  HttpRequestableObjectError.sessionError
                dispatcher.setNeedsDisplay(tooltip: tooltip)
                dispatcher.viewDidChangeSuperview(targetView, identifier: TooltipViewIdentifierMock)
                expect(router.displayedTooltips).toAfterTimeout(beEmpty())
            }

            context("when tooltip is displayed") {
                beforeEach {
                    let tooltip = TestHelpers.generateTooltip(id: "test", autoCloseSeconds: 10)
                    dispatcher.setNeedsDisplay(tooltip: tooltip)
                    dispatcher.viewDidMoveToWindow(targetView, identifier: TooltipViewIdentifierMock)
                    expect(router.displayedTooltips).toEventuallyNot(beEmpty())
                }

                it("will update currently displayed tooltip when the target view changed appeared") {
                    router.displayedTooltips = []
                    dispatcher.viewDidMoveToWindow(targetView, identifier: TooltipViewIdentifierMock)
                    expect(router.displayedTooltips).toEventuallyNot(beEmpty())
                }

                it("will update currently displayed tooltip when the target view changed its superview") {
                    router.displayedTooltips = []
                    dispatcher.viewDidChangeSuperview(targetView, identifier: TooltipViewIdentifierMock)
                    expect(router.displayedTooltips).toEventuallyNot(beEmpty())
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
                    expect(router.displayedTooltips.last?.id).toEventually(equal("test.auto"))

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
                    expect(router.displayedTooltips).toEventuallyNot(beEmpty())
                }

                it("will decrement impressionsLeft") {
                    router.completeDisplayingTooltip(cancelled: false)
                    expect(campaignRepository.decrementImpressionsCalls).toEventually(equal(1))
                }

                it("will not decrement impressionsLeft when display was cancelled") {
                    router.completeDisplayingTooltip(cancelled: true)
                    expect(campaignRepository.decrementImpressionsCalls).toAfterTimeout(equal(0))
                }

                it("will remove the tooltip from queue") {
                    router.completeDisplayingTooltip(cancelled: false)
                    expect(dispatcher.queuedTooltips).toEventuallyNot(contain(tooltip))
                }
            }

            context("when delegate is set") {

                var delegate: Delegate!

                beforeEach {
                    delegate = Delegate()
                    dispatcher.delegate = delegate
                }

                it("will call delegate if contexts are present") {
                    let tooltip = TestHelpers.generateTooltip(id: "test", title: "[Tooltip][ctx] title")
                    dispatcher.setNeedsDisplay(tooltip: tooltip)
                    expect(delegate.wasShouldShowCalled).toEventually(beTrue())
                }

                it("will not call delegate if contexts are not present") {
                    let tooltip = TestHelpers.generateTooltip(id: "test", title: "[Tooltip] title")
                    dispatcher.setNeedsDisplay(tooltip: tooltip)
                    expect(delegate.wasShouldShowCalled).toAfterTimeout(beFalse())
                }

                context("and contexts are approved") {
                    beforeEach {
                        delegate.shouldShowCampaign = true
                    }

                    it("will display newly added campaigns") {
                        let firstTooltip = TestHelpers.generateTooltip(id: "test1", title: "[Tooltip][ctx1] title")
                        let secondTooltip = TestHelpers.generateTooltip(id: "test2", title: "[Tooltip][ctx2] title")
                        dispatcher.setNeedsDisplay(tooltip: firstTooltip)
                        dispatcher.setNeedsDisplay(tooltip: secondTooltip)

                        expect(router.displayedTooltips).toEventually(elementsEqual([firstTooltip, secondTooltip]))
                    }

                    it("will not restore impressions left value") {
                        let tooltip = TestHelpers.generateTooltip(id: "test", title: "[Tooltip][ctx] title")
                        dispatcher.setNeedsDisplay(tooltip: tooltip)
                        router.completeDisplayingTooltip(cancelled: false)
                        expect(campaignRepository.incrementImpressionsCalls).toAfterTimeout(equal(0))
                    }
                }

                context("and contexts are not approved") {
                    beforeEach {
                        delegate.shouldShowCampaign = false
                    }

                    it("will proceed with dispatching the next tooltip") {
                        let firstTooltip = TestHelpers.generateTooltip(id: "test1", title: "[Tooltip][ctx1] title")
                        let secondTooltip = TestHelpers.generateTooltip(id: "test2", title: "[Tooltip] title")
                        dispatcher.setNeedsDisplay(tooltip: firstTooltip)
                        dispatcher.setNeedsDisplay(tooltip: secondTooltip)

                        expect(router.displayedTooltips).toEventually(equal([secondTooltip]))
                        expect(router.displayedTooltips).toAfterTimeout(haveCount(1))
                    }

                    it("will not display campaigns with context") {
                        let tooltip = TestHelpers.generateTooltip(id: "test", title: "[Tooltip][ctx] title")
                        dispatcher.setNeedsDisplay(tooltip: tooltip)
                        expect(router.displayedTooltips).toAfterTimeout(beEmpty())
                    }

                    it("will always dispatch test campaigns") {
                        let tooltip = TestHelpers.generateTooltip(id: "test", title: "[Tooltip][ctx] title", isTest: true)
                        dispatcher.setNeedsDisplay(tooltip: tooltip)
                        expect(router.displayedTooltips).toEventually(equal([tooltip]))
                    }

                    it("will not decrement impressions left value (cancelled display)") {
                        let tooltip = TestHelpers.generateTooltip(id: "test", title: "[Tooltip][ctx] title")
                        dispatcher.setNeedsDisplay(tooltip: tooltip)
                        router.completeDisplayingTooltip(cancelled: true)
                        expect(campaignRepository.decrementImpressionsCalls).toAfterTimeout(equal(0))
                    }
                }
            }
        }
    }
}

private class Delegate: TooltipDispatcherDelegate {
    private(set) var wasShouldShowCalled = false
    var shouldShowCampaign = true

    func shouldShowTooltip(title: String, contexts: [String]) -> Bool {
        wasShouldShowCalled = true
        return shouldShowCampaign
    }
}
