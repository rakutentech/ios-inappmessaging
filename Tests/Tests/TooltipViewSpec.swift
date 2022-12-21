import Quick
import Nimble
@testable import RInAppMessaging

class TooltipViewSpec: QuickSpec {

    override func spec() {

        describe("TooltipView") {

            var tooltipView: TooltipView!
            var presenter: TooltipPresenterMock!

            beforeEach {
                presenter = TooltipPresenterMock()
                tooltipView = TooltipView(presenter: presenter)
            }

            context("when calling startAutoDisappearIfNeeded") {

                it("will have nil timer before calling the method") {
                    expect(tooltipView.autoCloseTimer).to(beNil())
                }

                it("will start the timer") {
                    tooltipView.startAutoDisappearIfNeeded(seconds: 5)
                    expect(tooltipView.autoCloseTimer).toNot(beNil())
                }

                it("will ignore subsequent calls") {
                    tooltipView.startAutoDisappearIfNeeded(seconds: 5)
                    let firstTimer = tooltipView.autoCloseTimer
                    tooltipView.startAutoDisappearIfNeeded(seconds: 1)
                    expect(tooltipView.autoCloseTimer).to(equal(firstTimer))
                }

                it("will call presenter's didTapExitButton method when timer has fired") {
                    tooltipView.startAutoDisappearIfNeeded(seconds: 5)
                    tooltipView.autoCloseTimer?.fire()
                    expect(presenter.wasDidTapExitButtonCalled).to(beTrue())
                }
            }

            context("onDeinit closure") {
                it("will be called when instance is initialized") {
                    waitUntil { done in
                        tooltipView.onDeinit = {
                            done()
                        }
                        tooltipView = nil
                    }
                }
            }
        }
    }
}
