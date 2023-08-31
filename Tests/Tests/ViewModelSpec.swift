import Quick
import Nimble

@testable import RInAppMessaging

class ViewModelSpec: QuickSpec {

    override func spec() {

        describe("OverlayViewModel") {
            context("when calling hasText") {

                func createViewModel(header: String?,
                                     messageBody: String?) -> OverlayViewModel {
                    .init(image: nil, backgroundColor: .black, title: "",
                          messageBody: messageBody,
                          header: header,
                          titleColor: .black, headerColor: .black, messageBodyColor: .black,
                          isHTML: false, showOptOut: true, showButtons: true, isDismissable: true)
                }

                it("should return true if bodyMessage is not nil") {
                    let viewModel = createViewModel(header: nil, messageBody: "body")
                    expect(viewModel.hasText).to(beTrue())
                }

                it("should return true if header is not nil") {
                    let viewModel = createViewModel(header: "header", messageBody: nil)
                    expect(viewModel.hasText).to(beTrue())
                }

                it("should return false if bodyMessage and header are nil") {
                    let viewModel = createViewModel(header: nil, messageBody: nil)
                    expect(viewModel.hasText).to(beFalse())
                }

                it("should return false if bodyMessage and header are empty") {
                    let viewModel = createViewModel(header: "", messageBody: "")
                    expect(viewModel.hasText).to(beFalse())
                }
            }
        }
    }
}
