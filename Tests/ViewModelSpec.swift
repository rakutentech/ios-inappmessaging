import Quick
import Nimble

@testable import RInAppMessaging

class ViewModelSpec: QuickSpec {

    override func spec() {

        describe("FullViewModel") {
            context("when calling hasText") {

                func createViewModel(header: String?,
                                     messageBody: String?,
                                     messageLowerBody: String?) -> FullViewModel {
                    return .init(image: nil, backgroundColor: .black, title: "",
                                 messageBody: messageBody,
                                 messageLowerBody: messageLowerBody,
                                 header: header,
                                 titleColor: .black, headerColor: .black, messageBodyColor: .black,
                                 isHTML: false, showOptOut: true, showButtons: true)
                }

                it("should return true if bodyMessage is not nil") {
                    let viewModel = createViewModel(header: nil, messageBody: "body", messageLowerBody: nil)
                    expect(viewModel.hasText).to(beTrue())
                }

                it("should return true if header is not nil") {
                    let viewModel = createViewModel(header: "header", messageBody: nil, messageLowerBody: nil)
                    expect(viewModel.hasText).to(beTrue())
                }

                it("should return true if messageLowerBody is not nil") {
                    let viewModel = createViewModel(header: nil, messageBody: nil, messageLowerBody: "lowerBody")
                    expect(viewModel.hasText).to(beTrue())
                }

                it("should return false if bodyMessage, header and messageLowerBody are nil") {
                    let viewModel = createViewModel(header: nil, messageBody: nil, messageLowerBody: nil)
                    expect(viewModel.hasText).to(beFalse())
                }

                it("should return false if bodyMessage, header and messageLowerBody are empty") {
                    let viewModel = createViewModel(header: "", messageBody: "", messageLowerBody: "")
                    expect(viewModel.hasText).to(beFalse())
                }
            }
        }
    }
}
