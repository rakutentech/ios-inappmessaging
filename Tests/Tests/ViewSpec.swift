import Quick
import Nimble
import WebKit
@testable import RInAppMessaging

class ViewSpec: QuickSpec {

    override func spec() {

        describe("BaseView default implementation") {

            var view: BaseViewTestObject!
            var parentView: UIView!

            beforeEach {
                view = BaseViewTestObject()
                parentView = UIView()
                UIApplication.shared.keyWindow?.addSubview(parentView)
            }
            afterEach {
                parentView.removeFromSuperview()
            }

            context("when show is called") {

                it("will save onDismiss action") {
                    waitUntil { done in
                        let onDismiss: (Bool) -> Void = { _ in done() }
                        view.show(parentView: parentView, onDismiss: onDismiss)
                        expect(view.onDismiss).toNot(beNil())
                        view.onDismiss?(true)
                    }
                }

                it("will call animateOnShow") {
                    view.show(parentView: parentView, onDismiss: { _ in })
                    expect(view.wasAnimateOnShowCalled).to(beTrue())
                }

                it("will disable user interaction in parent view for the time of animation") {
                    view.show(parentView: parentView, onDismiss: { _ in })
                    expect(view.superview?.isUserInteractionEnabled).to(beFalse())
                    expect(view.wasAnimationCompletionCalled).toEventually(beTrue())
                    expect(view.superview?.isUserInteractionEnabled).to(beTrue())
                }
            }

            context("when dismiss is called") {

                it("will call onDismiss closure with `false` parameter") {
                    waitUntil { done in
                        view.show(parentView: parentView, onDismiss: { cancelled in
                            expect(cancelled).to(beFalse())
                            done()
                        })
                        view.dismiss()
                    }
                }

                it("will remove itself from superview") {
                    view.show(parentView: parentView, onDismiss: { _ in })
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
                expect(view.mode).to(equal(Mode.none))
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
                expect(scriptHandler.result).toAfterTimeoutNot(equal("Echo"))

                webView.removeFromSuperview()
            }

            it("will prevent execution of javascript code in web view using `evaluateJavaScript()`") {
                let webView = view.createWebView(withHtmlString: "<body>Text</body>", andFrame: .zero)

                waitUntil(timeout: .seconds(10)) { done in
                    webView.evaluateJavaScript("document.body.innerHTML") { (_, error) in
                        expect((error as NSError?)?.code).to(equal(4))
                        expect((error as NSError?)?.domain).to(equal("WKErrorDomain"))
                        done()
                    }
                }
            }
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

        describe("ModalView with CustomJson") {
            var view: ModalView!
            var presenter: FullViewPresenterMock!

            beforeEach {
                BundleInfoMocked.bundleMock = BundleMock()
                RInAppMessaging.bundleInfo = BundleInfoMocked.self
                RInAppMessaging.deinitializeModule()

                presenter = FullViewPresenterMock()
                view = ModalView(presenter: presenter)
                presenter.view = view
            }

            afterEach {
                RInAppMessaging.bundleInfo = BundleInfo.self
            }

            it("will have dark background color if CustomJson has valid value") {
                view.setup(viewModel: TestHelpers.generateFullViewModel(customJson: CustomJson(background: BackgroundColor(opacity: 0.6))))
                expect(view.backgroundViewColor).to(equal(.black.withAlphaComponent(0.6)))

                view.setup(viewModel: TestHelpers.generateFullViewModel(customJson: CustomJson(background: BackgroundColor(opacity: 0))))
                expect(view.backgroundViewColor).to(equal(.black.withAlphaComponent(0)))

                view.setup(viewModel: TestHelpers.generateFullViewModel(customJson: CustomJson(background: BackgroundColor(opacity: 1))))
                expect(view.backgroundViewColor).to(equal(.black.withAlphaComponent(1)))
            }

            it("will have default background color if CustomJson has invalid value") {
                view.setup(viewModel: TestHelpers.generateFullViewModel(customJson: CustomJson(background: BackgroundColor(opacity: 1.2))))
                expect(view.backgroundViewColor).toNot(equal(.black.withAlphaComponent(1.2)))
                expect(view.backgroundViewColor).to(equal(.black.withAlphaComponent(0.14)))

                view.setup(viewModel: TestHelpers.generateFullViewModel(customJson: CustomJson(background: BackgroundColor(opacity: -1))))
                expect(view.backgroundViewColor).toNot(equal(.black.withAlphaComponent(-1)))
                expect(view.backgroundViewColor).to(equal(.black.withAlphaComponent(0.14)))
            }

            it("will have default background color if CustomJson has nil value for any parameters") {
                view.setup(viewModel: TestHelpers.generateFullViewModel(customJson: CustomJson(background: nil)))
                expect(view.backgroundViewColor).to(equal(.black.withAlphaComponent(0.14)))

                view.setup(viewModel: TestHelpers.generateFullViewModel(customJson: CustomJson(background: BackgroundColor(opacity: nil))))
                expect(view.backgroundViewColor).to(equal(.black.withAlphaComponent(0.14)))

                view.setup(viewModel: TestHelpers.generateFullViewModel(customJson: nil))
                expect(view.backgroundViewColor).to(equal(.black.withAlphaComponent(0.14)))
            }

            context("with Carousel Data") {
                let carouselData = TestHelpers.carouselData

                it("it will display Carousel view and Carousel Page Control if the data is valid") {
                    view.setup(viewModel: TestHelpers.generateFullViewCarouselModel(carouselData: carouselData))
                    expect(view.carouselView).toNot(beNil())
                    expect(view.carouselView.isHidden).to(beFalse())
                    expect(view.carouselView.collectionView.numberOfItems(inSection: 0)).to(equal(carouselData.count))

                    expect(view.carouselView.carouselPageControl.isHidden).to(beFalse())
                    expect(view.carouselView.carouselPageControl.numberOfPages).to(equal(carouselData.count))
                    expect(view.carouselView.carouselPageControl.currentPage).to(equal(0))

                    let indexPath = IndexPath(item: 0, section: 0)
                    let cell = view.carouselView.collectionView(view.carouselView.collectionView, cellForItemAt: indexPath)
                    expect(cell).to(beAKindOf(CarouselCell.self))
                }

                it("it will not display Carousel view and Carousel Page Control if custom Json has valid modify modifyModal size specs") {
                    presenter.isValidSize = true
                    view.setup(viewModel: TestHelpers.generateFullViewCarouselModel(carouselData: carouselData))
                    expect(view.carouselView.isHidden).to(beTrue())
                    expect(view.carouselView.carouselPageControl.isHidden).to(beTrue())
                }

                it("it will not display Carousel view and Carousel Page Control if the data is valid but campaign has header and body text") {

                    view.setup(viewModel: TestHelpers.generateFullViewModel(carouselData: carouselData))
                    expect(view.carouselView.isHidden).to(beTrue())
                    expect(view.carouselView.carouselPageControl.isHidden).to(beTrue())
                }

                it("it will display Carousel view and Carousel Page Control if some images are nil") {
                    let carouselData = [CarouselData(image: UIImage(named: "istockphoto-1047234038"), altText: "error loading image", link: "https://www.google.com"),
                                                                   CarouselData(image: nil, altText: nil, link: "https://www.google1.com"),
                                                                   CarouselData(image: nil, altText: "error loading image2", link: "https://www.google2.com")]

                    view.setup(viewModel: TestHelpers.generateFullViewCarouselModel(carouselData: carouselData))
                    expect(view.carouselView).toNot(beNil())
                    expect(view.carouselView.isHidden).to(beFalse())
                    expect(view.carouselView.collectionView.numberOfItems(inSection: 0)).to(equal(carouselData.count))

                    expect(view.carouselView.carouselPageControl.isHidden).to(beFalse())
                    expect(view.carouselView.carouselPageControl.numberOfPages).to(equal(carouselData.count))
                    expect(view.carouselView.carouselPageControl.currentPage).to(equal(0))

                    let indexPath = IndexPath(item: 2, section: 0) // index path with nil image
                    let cell = view.carouselView.collectionView(view.carouselView.collectionView, cellForItemAt: indexPath)
                    expect(cell).to(beAKindOf(CarouselCell.self))
                }

                it("it will scroll to the correct collection view page on swipe") {
                    view.setup(viewModel: TestHelpers.generateFullViewCarouselModel(carouselData: carouselData))

                    view.carouselView.collectionView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
                    view.carouselView.collectionView.contentOffset.x = 300 // Scroll to the second item
                    view.carouselView.pageControlValueChanged()
                    view.carouselView.scrollViewDidScroll(view.carouselView.collectionView)
                    expect(view.carouselView.carouselPageControl.currentPage).to(equal(1))

                    view.carouselView.collectionView.contentOffset.x = 600 // Scroll to the third item
                    view.carouselView.pageControlValueChanged()
                    view.carouselView.scrollViewDidScroll(view.carouselView.collectionView)
                    expect(view.carouselView.carouselPageControl.currentPage).to(equal(2))
                }
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

class BaseViewTestObject: UIView, BaseView {
    static var viewIdentifier: String { "BaseViewTest" }

    var basePresenter: BaseViewPresenterType = BaseViewPresenterMock()
    var onDismiss: ((_ cancelled: Bool) -> Void)?
    private(set) var wasAnimateOnShowCalled = false
    private(set) var wasAnimationCompletionCalled = false

    func animateOnShow(completion: @escaping () -> Void) {
        wasAnimateOnShowCalled = true
        DispatchQueue.main.async {
            self.wasAnimationCompletionCalled = true
            completion()
        }
    }
    func constraintsForParent(_ parent: UIView) -> [NSLayoutConstraint] { [] }
}

class BaseViewPresenterMock: BaseViewPresenterType {
    var carouselData: [CarouselData]?
    var campaign: Campaign!
    var impressions: [Impression] = []
    var impressionService: ImpressionServiceType = ImpressionServiceMock()
    var associatedImage: UIImage?

    func viewDidInitialize() { }
    func handleButtonTrigger(_ trigger: Trigger?) { }
    func optOutCampaign() { }
}

class FullViewPresenterMock: FullViewPresenterType {
    var isValidSize = false
    var isValidPosition = false

    func validateAndAdjustModifyModal(modal: ModifyModal?) -> (isValidSize: Bool, isValidPosition: Bool, updatedModal: ModifyModal?) {
        return (isValidSize, isValidPosition, modal)
    }

    var carouselData: [CarouselData]?
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
    func didClickCampaignImage(url: String?) { }
}

class SlideUpViewPresenterMock: SlideUpViewPresenterType {
    var carouselData: [CarouselData]?
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
}

extension FullViewModel {
    static var empty: FullViewModel {
        .init(image: nil,
              backgroundColor: .black,
              title: "",
              messageBody: "",
              header: "",
              titleColor: .black,
              headerColor: .black,
              messageBodyColor: .black,
              isHTML: false,
              showOptOut: true,
              showButtons: true,
              isDismissable: true,
              customJson: nil,
              carouselData: nil)
    }
}

extension SlideUpViewModel {
    static var empty: SlideUpViewModel {
        .init(slideFromDirection: .bottom,
              backgroundColor: .black,
              messageBody: "",
              messageBodyColor: .black,
              isDismissable: true)
    }
}

private class WebViewScriptMessageHandler: NSObject, WKScriptMessageHandler {

    private(set) var result = ""

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        result = (message.body as? String) ?? "Error"
    }
}
