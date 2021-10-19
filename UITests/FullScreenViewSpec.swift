import Quick
import Nimble
import RSDKUtils
import class Shock.MockServer

class FullScreenViewSpec: QuickSpec {

    override func spec() {

        var mockServer: MockServer!
        var app: XCUIApplication!
        var iamView: XCUIElement {
            app.otherElements.element(matching: NSPredicate(format: "identifier BEGINSWITH[cd] 'IAMView'"))
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

        describe("Full-screen campaign view") {

            context("when clicking X button") {

                beforeEach {
                    launchAppIfNecessary(context: "full-text-only")
                    if !iamView.exists {
                        app.buttons["login_successful"].tap()
                        expect(iamView.exists).toEventually(beTrue())
                    }
                }

                it("should close the campaign") {
                    iamView.buttons["exitButton"].tap()
                    expect(iamView.exists).to(beFalse())
                }

                it("should have 44pt touch area") {
                    let exitButtonCenter = iamView.buttons["exitButton"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    let upperLeftCorner = exitButtonCenter.withOffset(CGVector(dx: -22, dy: -22))
                    upperLeftCorner.tap()
                    expect(iamView.exists).to(beFalse())

                    app.buttons["login_successful"].tap() // show the message again
                    expect(iamView.exists).toEventually(beTrue())
                    let bottomRightCorner = exitButtonCenter.withOffset(CGVector(dx: 21, dy: 21)) // points on max edges are not counted
                    bottomRightCorner.tap()
                    expect(iamView.exists).to(beFalse())
                }
            }

            context("without controls") {

                beforeEach {
                    launchAppIfNecessary(context: "full-text-only")
                    if !iamView.exists {
                        app.buttons["login_successful"].tap()
                        expect(iamView.exists).toEventually(beTrue())
                    }
                }

                it("should not display any buttons") {
                    expect(iamView.buttons["Button0"].exists).to(beFalse())
                    expect(iamView.buttons["Button1"].exists).to(beFalse())
                }

                it("should not display opt-out checkbox") {
                    expect(iamView.buttons["optOutView"].exists).to(beFalse())
                }
            }

            context("with action butttons") {

                beforeEach {
                    launchAppIfNecessary(context: "full-controls")
                    if !iamView.exists {
                        app.buttons["custom_test"].tap()
                        expect(iamView.exists).toEventually(beTrue())
                    }
                }

                it("should display 2 buttons") {
                    expect(iamView.buttons["Button0"].exists).to(beTrue())
                    expect(iamView.buttons["Button1"].exists).to(beTrue())
                }

                it("should close campaign after tapping button 1") {
                    iamView.buttons["Button0"].tap()
                    expect(iamView.exists).to(beFalse())
                }

                it("should close campaign after tapping button 2") {
                    iamView.buttons["Button1"].tap()
                    expect(iamView.exists).to(beFalse())
                    app = nil // restart the app to avoid dealing with race condition caused by triggered campaign
                }

                it("should trigger another campaign after tapping button 2") {
                    iamView.buttons["Button1"].tap()
                    expect(iamView.exists).to(beFalse())
                    expect(iamView.exists).toEventually(beTrue())
                }
            }

            context("with opt-out option") {

                beforeEach {
                    launchAppIfNecessary(context: "full-controls")
                    if !iamView.exists {
                        expect(app.buttons["custom_test"].exists).to(beTrue())
                        app.buttons["custom_test"].tap()
                        expect(iamView.exists).toEventually(beTrue())
                    }
                }

                it("should display opt out") {
                    expect(iamView.buttons["Do not show me this message again"].exists).to(beTrue())
                }

                it("should not display the campaign again if opt out button was checked") {
                    iamView.buttons["Do not show me this message again"].tap()
                    iamView.buttons["exitButton"].tap()
                    app.buttons["custom_test"].tap()
                    expect(iamView.exists).toAfterTimeout(beFalse())
                    app = nil // force clean launch to clear opt-out setting
                }
            }

            context("with text-only layout") {
                var iamView: XCUIElement {
                    app.otherElements[#"IAMView-FullScreen data-qa="textOnly""#]
                }

                beforeEach {
                    launchAppIfNecessary(context: "full-text-only")
                    if !iamView.exists {
                        app.buttons["login_successful"].tap()
                        expect(iamView.exists).toEventually(beTrue())
                    }
                }

                it("should not contain image") {
                    expect(iamView.images.count).to(equal(0))
                }

                it("should contain text elements") {
                    expect(iamView.otherElements.otherElements["textView"].staticTexts["bodyMessage"].exists).to(beTrue())
                    expect(iamView.otherElements.otherElements["textView"].staticTexts["headerMessage"].exists).to(beTrue())
                }
            }

            context("with text & image layout") {
                var iamView: XCUIElement {
                    app.otherElements[#"IAMView-FullScreen data-qa="textAndImage""#]
                }

                beforeEach {
                    launchAppIfNecessary(context: "full-text-image")
                    if !iamView.exists {
                        app.buttons["login_successful"].tap()
                        expect(iamView.exists).toEventually(beTrue())
                    }
                }

                it("should contain image element") {
                    expect(iamView.images["imageView"].exists).to(beTrue())
                }

                it("should contain text elements") {
                    expect(iamView.otherElements.otherElements["textView"].staticTexts["bodyMessage"].exists).to(beTrue())
                    expect(iamView.otherElements.otherElements["textView"].staticTexts["headerMessage"].exists).to(beTrue())
                }
            }

            context("with image-only layout") {
                var iamView: XCUIElement {
                    app.otherElements[#"IAMView-FullScreen data-qa="imageOnly""#]
                }

                beforeEach {
                    launchAppIfNecessary(context: "full-image-only")
                    if !iamView.exists {
                        app.buttons["login_successful"].tap()
                        expect(iamView.exists).toEventually(beTrue())
                    }
                }

                it("should contain image element") {
                    expect(iamView.images["imageView"].exists).to(beTrue())
                }

                it("should not contain text elements") {
                    expect(iamView.otherElements.otherElements["textView"].staticTexts.count).to(equal(0))
                }
            }
        }
    }
}
