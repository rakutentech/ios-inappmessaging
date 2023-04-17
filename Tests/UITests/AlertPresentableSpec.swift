import XCTest
import Quick
import Nimble
import class Shock.MockServer

class AlertPresentableSpec: QuickSpec {

    override func spec() {

        var mockServer: MockServer!
        var app: XCUIApplication!

        func launchAppIfNecessary(context: String) {
            mockServer.setup(route: MockServerHelper.pingRouteMock(jsonStub: context))
            mockServer.start()

            guard app == nil || !app.launchArguments.joined(separator: " ").contains(context) else {
                return
            }
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

        describe("AlertPresentable") {

            context("with modal view") {

                var iamView: XCUIElement {
                    app.otherElements.element(matching: NSPredicate(format: "identifier BEGINSWITH[cd] 'IAMView'"))
                }

                beforeEach {
                    launchAppIfNecessary(context: "modal-controls-invalid-url")
                    if !iamView.exists {
                        app.buttons["purchase_successful"].tap()
                        expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
                    }
                }

                it("should show error alert after tapping button 1 and close campaign") {
                    iamView.buttons["Button0"].tap()
                    expect(app.alerts.element.staticTexts["Page not found"].exists).to(beTrue())
                    app.alerts.element.buttons["Close"].tap()
                }
            }

            context("with slide up view") {

                var iamView: XCUIElement {
                    app.otherElements["IAMView-SlideUp"]
                }
                var content: XCUIElement {
                    iamView.buttons["bodyMessage"]
                }

                beforeEach {
                    launchAppIfNecessary(context: "slide-up-trigger-invalid-url")
                    if !iamView.exists {
                        app.buttons["purchase_successful"].tap()
                        expect(iamView.exists).toEventually(beTrue(), timeout: .seconds(2))
                    }
                }

                it("should show error alert after tapping button 1 and close campaign") {
                    content.tap()
                    expect(app.alerts.element.staticTexts["Page not found"].exists).to(beTrue())
                    app.alerts.element.buttons["Close"].tap()
                    iamView.buttons["exitButton"].tap()
                    expect(iamView.exists).to(beFalse())
                }
            }
        }
    }
}
