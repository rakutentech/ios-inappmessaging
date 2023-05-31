import XCTest
import Quick
import Nimble
import class Shock.MockServer

class ToolTipViewSpec: QuickSpec {
    override func spec() {

        var mockServer: MockServer!
        var app: XCUIApplication!
        var iamView: XCUIElement {
            app.otherElements["IAMView-Tooltip"]
        }
        var content: XCUIElement {
            iamView.buttons["bodyMessage"]
        }

        func launchAppIfNecessary(context: String) {
            mockServer.setup(route: MockServerHelper.pingRouteMock(jsonStub: context))
            mockServer.start()

            guard app == nil || !app.launchArguments.joined(separator: " ").contains(context) else {
                return
            }
            self.continueAfterFailure = false
            app = XCUIApplication()
            app.launchArguments.append("--uitesting")
            app.launchArguments.append("-context \(context)")
            app.launch()
            app.buttons["UIKit"].tap()
            app.buttons["app_launch"].tap()
        }
        beforeEach {
            mockServer = MockServerHelper.setupNewServer(route: MockServerHelper.standardRouting)
        }

        afterEach {
            mockServer.stop()
        }
        describe("Tooltip View") {
            context("when clicking X button") {
                beforeEach {
                    launchAppIfNecessary(context: "tooltip-data")
                    if !iamView.exists {
                        app.buttons["open_modal_page"].tap()
                        expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
                    }
                }
                it("should close the tooltip") {
                    expect(iamView.buttons["IAM.tooltip.exitButton"].exists).to(beTrue())
                    iamView.buttons["IAM.tooltip.exitButton"].tap()
                    expect(iamView.exists).to(beFalse())
                }
            }
            context("when clicking X button for testing touch area") {
                beforeEach {
                    launchAppIfNecessary(context: "tooltip-toucharea")
                    if !iamView.exists {
                        app.buttons["open_modal_page"].tap()
                        expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
                    }
                }
                it("should have 44pt touch area") {
                    let exitButtonCenter = iamView.buttons["IAM.tooltip.exitButton"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    let upperLeftCorner = exitButtonCenter.withOffset(
                        CGVector(dx: -21.5, dy: -21.5)) // reduced by .5 for cases when exit button has x.5 x/y position
                    upperLeftCorner.tap()
                    expect(iamView.exists).to(beFalse())
                }
            }
            context("when trigering tooltip after closing") {
                beforeEach {
                    launchAppIfNecessary(context: "tooltip-autodisappear")
                    if !iamView.exists {
                        app.buttons["open_modal_page"].tap()
                        expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
                    }
                }
                it("tooltip should not reappear") {
                    expect(iamView.buttons["IAM.tooltip.exitButton"].exists).to(beTrue())
                    iamView.buttons["IAM.tooltip.exitButton"].tap()
                    expect(iamView.exists).to(beFalse())
                    app.buttons["return_to_home"].tap()
                    app.buttons["open_modal_page"].tap()
                    expect(iamView.buttons["IAM.tooltip.exitButton"].exists).to(beFalse())
                    expect(iamView.exists).to(beFalse())
                }
            }
            context("when trigering tooltip after closing") {
                beforeEach {
                    launchAppIfNecessary(context: "tooltip-data")
                    if !iamView.exists {
                        app.buttons["open_modal_page"].tap()
                        expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
                    }
                }
                it("tooltip should not reappear") {
                    expect(iamView.buttons["IAM.tooltip.exitButton"].exists).to(beTrue())
                    iamView.buttons["IAM.tooltip.exitButton"].tap()
                    expect(iamView.exists).to(beFalse())
                    app.buttons["return_to_home"].tap()
                    app.buttons["open_modal_page"].tap()
                    expect(iamView.buttons["IAM.tooltip.exitButton"].exists).to(beFalse())
                    expect(iamView.exists).to(beFalse())
                }
            }
            context("when trigering tooltip with autodisppear") {
                beforeEach {
                    launchAppIfNecessary(context: "tooltip-autodisappear")
                    if !iamView.exists {
                        app.buttons["open_modal_page"].tap()
                        expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
                    }
                }
                it("tooltip should autodisappear after the specified time") {
                    expect(iamView.exists).toEventually(beFalse(), timeout: .seconds(6))
                }
            }
        }
    }
}
