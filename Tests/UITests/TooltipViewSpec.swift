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

        func launchApp(context: String) {
            mockServer.setup(route: MockServerHelper.pingRouteMock(jsonStub: context))
            mockServer.start()
            self.continueAfterFailure = false
            app = XCUIApplication()
            app.launchArguments.append("--uitesting")
            app.launchArguments.append("-context \(context)")
            app.launch()
            app.buttons["UIKit"].tap()
        }
        beforeEach {
            mockServer = MockServerHelper.setupNewServer(route: MockServerHelper.standardRouting)
        }

        afterEach {
            mockServer.stop()
        }
        func displayAppLaunchTooltip() {
            app.buttons["app_launch"].tap()
            if !iamView.exists {
                app.buttons["open_modal_page"].tap()
                expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
            }
        }
        describe("Tooltip View") {
            context("when clicking X button") {
                beforeEach {
                    launchApp(context: "tooltip-data")
                }
                it("should close the tooltip") {
                    displayAppLaunchTooltip()
                    expect(iamView.buttons["IAM.tooltip.exitButton"].exists).to(beTrue())
                    iamView.buttons["IAM.tooltip.exitButton"].tap()
                    expect(iamView.exists).to(beFalse())
                }
                it("should have 44pt touch area") {
                    displayAppLaunchTooltip()
                    let exitButtonCenter = iamView.buttons["IAM.tooltip.exitButton"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    let upperLeftCorner = exitButtonCenter.withOffset(
                        CGVector(dx: -21.5, dy: -21.5)) // reduced by .5 for cases when exit button has x.5 x/y position
                    upperLeftCorner.tap()
                    expect(iamView.exists).to(beFalse())
                }
                it("should not reappear after closing") {
                    displayAppLaunchTooltip()
                    expect(iamView.buttons["IAM.tooltip.exitButton"].exists).to(beTrue())
                    iamView.buttons["IAM.tooltip.exitButton"].tap()
                    expect(iamView.exists).to(beFalse())
                    app.buttons["return_to_home"].tap()
                    app.buttons["open_modal_page"].tap()
                    expect(iamView.exists).to(beFalse())
                }
                it("should not reappear after logging another event") {
                    app.buttons["login_successful"].tap()
                    app.buttons["open_modal_page"].tap()
                    expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
                    expect(iamView.buttons["IAM.tooltip.exitButton"].exists).to(beTrue())
                    iamView.buttons["IAM.tooltip.exitButton"].tap()
                    app.buttons["return_to_home"].tap()
                    app.buttons["login_successful"].tap()
                    app.buttons["open_modal_page"].tap()
                    expect(iamView.exists).to(beFalse())
                }
            }
            context("when autodisppear is enabled") {
                beforeEach {
                    launchApp(context: "tooltip-data")
                }
                it("should disappear after the specified duration") {
                    displayAppLaunchTooltip()
                    expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(3))
                    expect(iamView.exists).toEventually(beFalse(), timeout: .seconds(6))
                }
            }
        }
    }
}
