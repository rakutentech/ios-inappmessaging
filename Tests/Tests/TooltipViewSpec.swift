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
