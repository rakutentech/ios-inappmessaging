import XCTest
import Quick
import Nimble
import class Shock.MockServer

class SlideUpViewSpec: QuickSpec {

    override func spec() {

        var mockServer: MockServer!
        var app: XCUIApplication!
        var iamView: XCUIElement {
            app.otherElements["IAMView-SlideUp"]
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
        }

        beforeEach {
            mockServer = MockServerHelper.setupNewServer(route: MockServerHelper.standardRouting)
        }

        afterEach {
            mockServer.stop()
        }

        describe("Slide-up campaign view") {

            context("trigger action with invalid message payload") {

                beforeEach {
                    launchAppIfNecessary(context: "slide-up-trigger-without-messageBody")
                    expect(iamView.exists).to(beFalse())
                    app.buttons["purchase_successful"].tap()
                }

                it("should not construct the slideup view") {
                    expect(iamView.exists).toAfterTimeout(beFalse(), timeout: 2)
                }
            }

            context("when clicking X button") {

                beforeEach {
                    launchAppIfNecessary(context: "slide-up-close")
                    if !iamView.exists {
                        app.buttons["login_successful"].tap()
                        expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
                    }
                }

                it("should close the campaign") {
                    expect(iamView.buttons["exitButton"].exists).to(beTrue())
                    iamView.buttons["exitButton"].tap()
                    expect(iamView.exists).to(beFalse())
                }

                it("should have 44pt touch area") {
                    let exitButtonCenter = iamView.buttons["exitButton"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    let upperLeftCorner = exitButtonCenter.withOffset(
                        CGVector(dx: -21.5, dy: -21.5)) // reduced by .5 for cases when exit button has x.5 x/y position
                    upperLeftCorner.tap()
                    expect(iamView.exists).to(beFalse())

                    app.buttons["login_successful"].tap() // show the message again
                    expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
                    let bottomRightCorner = exitButtonCenter.withOffset(CGVector(dx: 20.5, dy: 20.5)) // points on max edges are not counted
                    bottomRightCorner.tap()
                    expect(iamView.exists).to(beFalse())
                }
            }

            context("with redirect action") {

                beforeEach {
                    launchAppIfNecessary(context: "slide-up-close")
                    if !iamView.exists {
                        app.buttons["login_successful"].tap()
                        expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
                    }
                }

                it("should close campaign after tapping the content") {
                    content.tap()
                    expect(iamView.exists).to(beFalse())
                }
            }

            context("with trigger action") {

                beforeEach {
                    launchAppIfNecessary(context: "slide-up-trigger")
                    if !iamView.exists {
                        app.buttons["purchase_successful"].tap()
                        expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
                    }
                }

                it("should close campaign after tapping the content") {
                    content.tap()
                    expect(iamView.exists).to(beFalse())
                }

                it("should trigger another campaign after tapping the content") {
                    content.tap()
                    expect(iamView.exists).to(beFalse())
                    expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
                }

                context("when campaign is not dismissable") {

                    it("should not have exit button") {
                        expect(iamView.buttons["exitButton"].exists).to(beFalse())
                    }
                }
            }
        }
    }
}
