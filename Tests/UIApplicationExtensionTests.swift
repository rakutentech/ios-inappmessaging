import Quick
import Nimble
@testable import RInAppMessaging

class UIApplicationExtensionsTests: QuickSpec {

    override func spec() {

        describe("UIApplication+IAM") {

            let application = UIApplication.shared

            context("when calling getKeyWindow method") {

                let window = UIWindow()
                let originalWindow = UIApplication.shared.keyWindow

                afterEach {
                    originalWindow?.makeKeyAndVisible()
                }

                it("will return current key window (legacy)") {
                    window.makeKeyAndVisible()
                    expect(application.getKeyWindow()).to(equal(window))
                }

                // Tests below will run only on iOS 13+
                guard #available(iOS 13.0, *) else {
                    return
                }

                let scene = application.connectedScenes.first as? UIWindowScene

                it("will return key window from connected scene") {
                    expect(scene).toNot(beNil())
                    window.windowScene = scene
                    window.makeKeyAndVisible()
                    expect(application.getKeyWindow()).to(equal(window))
                }

                it("will return key window from connected scene with multiple windows") {
                    window.windowScene = scene
                    // keep window references till the end of the test
                    let windowA = UIWindow(windowScene: scene!)
                    let windowB = UIWindow(windowScene: scene!)
                    window.makeKeyAndVisible()

                    expect(scene?.windows.count).to(beGreaterThan(3))
                    expect(application.getKeyWindow()).to(equal(window))
                }
            }

            context("when calling getCurrentStatusBarStyle method") {

                it("will not return nil on iOS 13+") {
                    if #available(iOS 13.0, *) {
                        expect(application.statusBarStyle).toNot(beNil())
                    } else {
                        expect(application.statusBarStyle).to(beNil())
                    }
                }
            }
        }
    }
}
