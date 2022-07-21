import Quick
import Nimble
import WebKit
@testable import RInAppMessaging

final class OptOutMessageViewSpec: QuickSpec {

    override func spec() {
        describe("OptOutMessageView") {

            var optOutView: OptOutMessageView!

            beforeEach {
                optOutView = OptOutMessageView()
            }

            context("when setting useBrightColors") {

                context("and the value is true") {
                    beforeEach {
                        optOutView.useBrightColors = true
                    }

                    it("will set all UI elements to white") {
                        expect(optOutView.optOutMessage.textColor).to(equal(.white))
                        expect(optOutView.checkbox.uncheckedBorderColor).to(equal(.white))
                        expect(optOutView.checkbox.checkedBorderColor).to(equal(.white))
                        expect(optOutView.checkbox.checkmarkColor).to(equal(.white))
                    }
                }

                context("and the value is false") {
                    beforeEach {
                        optOutView.useBrightColors = false
                    }

                    it("will set all UI elements to black") {
                        expect(optOutView.optOutMessage.textColor).to(equal(.black))
                        expect(optOutView.checkbox.uncheckedBorderColor).to(equal(.black))
                        expect(optOutView.checkbox.checkedBorderColor).to(equal(.black))
                        expect(optOutView.checkbox.checkmarkColor).to(equal(.black))
                    }
                }
            }
        }
    }
}
