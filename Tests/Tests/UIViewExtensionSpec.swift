import Quick
import Nimble
import class UIKit.UIView
@testable import RInAppMessaging

class UIViewExtensionsSpec: QuickSpec {

    override func spec() {

        describe("UIView+IAM") {

            context("when calling findIAMViewSubview method") {

                let iamView = BaseViewTestObject()

                it("will find IAM view as a direct subview") {
                    let testView = UIView()
                    testView.addSubview(UIView())
                    testView.addSubview(iamView)
                    testView.addSubview(UIView())

                    expect(testView.findIAMView()).to(beIdenticalTo(iamView))
                }

                it("will find IAM view as a nested subview") {
                    let testView = UIView()
                    testView.addSubview(UIView())
                    testView.addSubview(UIView())
                    testView.subviews[0].addSubview(UIView())
                    testView.subviews[0].addSubview(UIView())
                    testView.subviews[0].subviews[1].addSubview(iamView)

                    expect(testView.findIAMView()).to(beIdenticalTo(iamView))
                }

                it("will find an instance of FullScreenView") {
                    let testView = UIView()
                    let fsView = FullScreenView(presenter: OverlayViewPresenterMock())
                    testView.addSubview(fsView)

                    expect(testView.findIAMView()).to(beIdenticalTo(fsView))
                }

                it("will find an instance of SlideUpView") {
                    let testView = UIView()
                    let suView = SlideUpView(presenter: SlideUpViewPresenterMock())
                    testView.addSubview(suView)

                    expect(testView.findIAMView()).to(beIdenticalTo(suView))
                }

                it("will find an instance of ModalView") {
                    let testView = UIView()
                    let moView = ModalView(presenter: OverlayViewPresenterMock())
                    testView.addSubview(moView)

                    expect(testView.findIAMView()).to(beIdenticalTo(moView))
                }
            }
        }
    }
}
