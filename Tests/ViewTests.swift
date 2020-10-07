import Quick
import Nimble
import WebKit
@testable import RInAppMessaging

class ViewTests: QuickSpec {

    override func spec() {

        describe("BaseView default implementation") {

            var view: BaseViewTestObject!

            beforeEach {
                view = BaseViewTestObject()
            }
            afterEach {
                // Clean up UIWindow. (first subview is UITransitionView)
                UIApplication.shared.keyWindow?.subviews.dropFirst().forEach {
                    $0.removeFromSuperview()
                }
            }

            context("when show is called") {

                it("will save onDismiss action") {
                    waitUntil { done in
                        let onDismiss = { done() }
                        view.show(accessibilityCompatible: false, onDismiss: onDismiss)
                        expect(view.onDismiss).toNot(beNil())
                        view.onDismiss?()
                    }
                }

                it("will add itself to the UIWindow's view when `accessibilityCompatible` is false") {
                    let window = UIApplication.shared.keyWindow
                    view.show(accessibilityCompatible: false, onDismiss: {})
                    expect(window?.subviews).to(containElementSatisfying({ $0 is BaseView }))
                }

                it("will add itself to the UIWindow's view main subview when `accessibilityCompatible` is true") {
                    let window = UIApplication.shared.keyWindow
                    let rootView = UIView()
                    window?.addSubview(rootView)

                    view.show(accessibilityCompatible: true, onDismiss: {})
                    expect(rootView.subviews).to(containElementSatisfying({ $0 is BaseView }))
                }

                it("will call animateOnShow") {
                    view.show(accessibilityCompatible: false, onDismiss: {})
                    expect(view.wasAnimateOnShowCalled).to(beTrue())
                }

                it("will not show when another one is still displayed") {
                    let window = UIApplication.shared.keyWindow
                    let anotherView = BaseViewTestObject()
                    anotherView.show(accessibilityCompatible: false, onDismiss: {})
                    expect(window?.subviews).to(contain(anotherView))

                    view.show(accessibilityCompatible: false, onDismiss: {})
                    expect(window?.subviews).toNot(contain(view))
                }
            }

            context("when dismiss is called") {

                it("will call onDismiss closure") {
                    waitUntil { done in
                        view.show(accessibilityCompatible: false, onDismiss: { done() })
                        view.dismiss()
                    }
                }

                it("will remove itself from superview") {
                    view.show(accessibilityCompatible: false, onDismiss: { })
                    expect(view.superview).toNot(beNil())
                    view.dismiss()
                    expect(view.superview).to(beNil())
                }
            }
        }

        describe("SlideUpView") {
            var view: SlideUpView!
            var presenter: SlideUpViewPresenterMock!

            beforeEach {
                presenter = SlideUpViewPresenterMock()
                view = SlideUpView(presenter: presenter)
                presenter.view = view
            }

            it("will call viewDidInitialize on presenter after init") {
                expect(presenter.wasViewDidInitializeCalled).to(beTrue())
            }

            it("will log impression when setup() is called") {
                view.setup(viewModel: SlideUpViewModel.empty)
                expect(presenter.impressions).to(haveCount(1))
                expect(presenter.impressions).to(containElementSatisfying({ $0.type == .impression }))
            }
        }

        describe("FullView (abstract implementation)") {
            var view: FullView!
            var presenter: FullViewPresenterMock!

            beforeEach {
                presenter = FullViewPresenterMock()
                view = FullView(presenter: presenter)
                presenter.view = view
            }

            it("will have .none mode set") {
                expect(view.mode).to(equal(FullViewMode.none))
            }

            it("will call viewDidInitialize on presenter after init") {
                expect(presenter.wasViewDidInitializeCalled).to(beTrue())
            }

            it("will ignore setup call") {
                view.setup(viewModel: FullViewModel.empty)
                expect(view.subviews).to(beEmpty())
            }

            it("will not log impression when setup() is called") {
                view.setup(viewModel: FullViewModel.empty)
                expect(presenter.impressions).to(beEmpty())
            }

            it("will prevent execution of web page's javascript code in web view") {
                let webView = view.createWebView(
                    withHtmlString: #"""
                        <body>
                            <script>
                                window.webkit.messageHandlers.echo.postMessage("Echo");
                            </script>
                        </body>
                    """#,
                    andFrame: CGRect(x: 0, y: 0, width: 100, height: 100))

                UIApplication.shared.keyWindow?.addSubview(webView)
                expect(webView.superview).toNot(beNil())

                let scriptHandler = WebViewScriptMessageHandler()
                webView.configuration.userContentController.add(scriptHandler, name: "echo")
                waitUntil(timeout: .seconds(2)) { done in
                    DispatchQueue.global(qos: .userInteractive).async {
                        sleep(1)
                        expect(scriptHandler.result).toNot(equal("Echo"))
                        done()
                    }
                }

                webView.removeFromSuperview()
            }

            //swiftlint:disable:next todo
            // FIXME: This test is disabled because it's failing on CI. Reason unknown
//            it("will prevent execution of javascript code in web view using `evaluateJavaScript()`") {
//                let webView = view.createWebView(withHtmlString: "<body>Text</body>", andFrame: .zero)
//
//                waitUntil(timeout: 5.0) { done in
//                    webView.evaluateJavaScript("document.body.innerHTML") { (_, error) in
//                        expect((error as NSError?)?.code).to(equal(4))
//                        expect((error as NSError?)?.domain).to(equal("WKErrorDomain"))
//                        done()
//                    }
//                }
//            }
        }

        describe("ModalView") {
            var view: ModalView!
            var presenter: FullViewPresenterMock!

            beforeEach {
                presenter = FullViewPresenterMock()
                view = ModalView(presenter: presenter)
                presenter.view = view
            }

            it("will have .modal mode set") {
                if case .modal = view.mode {
                    // expected
                } else {
                    fail("Expected ModalView to have .modal mode. Actual: \(view.mode)")
                }
            }

            it("will log impression when setup() is called") {
                view.setup(viewModel: FullViewModel.empty)
                expect(presenter.impressions).to(haveCount(1))
                expect(presenter.impressions).to(containElementSatisfying({ $0.type == .impression }))
            }
        }

        describe("FullScreenView") {
            var view: FullScreenView!
            var presenter: FullViewPresenterMock!

            beforeEach {
                presenter = FullViewPresenterMock()
                view = FullScreenView(presenter: presenter)
                presenter.view = view
            }

            it("will have .fullScreen mode set") {
                expect(view.mode).to(equal(.fullScreen))
            }

            it("will log impression when setup() is called") {
                view.setup(viewModel: FullViewModel.empty)
                expect(presenter.impressions).to(haveCount(1))
                expect(presenter.impressions).to(containElementSatisfying({ $0.type == .impression }))
            }
        }
    }
}

private class BaseViewTestObject: UIView, BaseView {
    var onDismiss: (() -> Void)?
    private(set) var wasAnimateOnShowCalled = false

    func animateOnShow() {
        wasAnimateOnShowCalled = true
    }
    func constraintsForParent(_ parent: UIView) -> [NSLayoutConstraint] { [] }
}

private class FullViewPresenterMock: FullViewPresenterType {
    var view: FullViewType?
    var campaign: Campaign!
    var impressions: [Impression] = []
    var impressionService: ImpressionServiceType = ImpressionServiceMock()
    var associatedImage: UIImage?

    private(set) var wasViewDidInitializeCalled = false

    func loadButtons() { }
    func didClickAction(sender: ActionButton) {}
    func didClickExitButton() { }
    func viewDidInitialize() {
        wasViewDidInitializeCalled = true
    }
    func handleButtonTrigger(_ trigger: Trigger?) { }
    func optOutCampaign() { }
    func loadResources() { }
}

private class SlideUpViewPresenterMock: SlideUpViewPresenterType {
    var view: SlideUpViewType?
    var campaign: Campaign!
    var impressions: [Impression] = []
    var impressionService: ImpressionServiceType = ImpressionServiceMock()
    var associatedImage: UIImage?

    private(set) var wasViewDidInitializeCalled = false

    func didClickContent() { }
    func didClickExitButton() { }
    func viewDidInitialize() {
        wasViewDidInitializeCalled = true
    }
    func handleButtonTrigger(_ trigger: Trigger?) { }
    func optOutCampaign() { }
    func loadResources() { }
}

extension FullViewModel {
    static var empty: FullViewModel {
        return .init(image: nil,
                     backgroundColor: .black,
                     title: "",
                     messageBody: "",
                     messageLowerBody: "",
                     header: "",
                     titleColor: .black,
                     headerColor: .black,
                     messageBodyColor: .black,
                     isHTML: false,
                     showOptOut: true,
                     showButtons: true)
    }
}

extension SlideUpViewModel {
    static var empty: SlideUpViewModel {
        return .init(slideFromDirection: .bottom,
                     backgroundColor: .black,
                     messageBody: "",
                     messageBodyColor: .black)
    }
}

private class WebViewScriptMessageHandler: NSObject, WKScriptMessageHandler {

    private(set) var result = ""

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        result = (message.body as? String) ?? "Error"
    }
}
