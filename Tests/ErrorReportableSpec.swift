import Quick
import Nimble
@testable import RInAppMessaging

class ErrorReportableSpec: QuickSpec {

    override func spec() {

        context("ErrorReportable object") {

            var reporter: ErrorReportableTestObject!
            var delegate: ErrorReportableDelegate!

            beforeEach {
                reporter = ErrorReportableTestObject()
                delegate = ErrorReportableDelegate()
                reporter.errorDelegate = delegate
            }

            it("will send reported error to the delegate") {
                reporter.reportError(description: "Error!", data: nil)
                expect(delegate.receivedError).toNot(beNil())
            }

            it("will send error with proper domain") {
                reporter.reportError(description: "Error!", data: nil)
                expect(delegate.receivedError?.domain)
                    .to(equal("InAppMessaging.ErrorReportableTestObject"))
            }

            it("will embedd provided data in the error object (dictionary)") {
                let data: [String: Any] = ["date": Date(), "number": 5]
                reporter.reportError(description: "Error!", data: data)

                let receivedData = delegate.receivedError?.userInfo["data"]
                expect(receivedData).toNot(beNil())
                expect(receivedData).to(beAKindOf(type(of: data)))
                expect(String(describing: receivedData ?? [:])).to(equal(String(describing: data)))
            }

            it("will embedd provided data in the error object (primitive)") {
                reporter.reportError(description: "Error!", data: 5)

                let receivedData = delegate.receivedError?.userInfo["data"]
                expect(receivedData).toNot(beNil())
                expect(receivedData).to(beAKindOf(Int.self))
                expect(receivedData as? Int).to(equal(5))
            }

            it("will embedd description string in the error object") {
                reporter.reportError(description: "Error!", data: nil)
                expect(delegate.receivedError?.localizedDescription).to(equal("InAppMessaging: Error!"))
            }
        }
    }
}

private class ErrorReportableTestObject: ErrorReportable {
    weak var errorDelegate: ErrorDelegate?
}

private class ErrorReportableDelegate: ErrorDelegate {
    private(set) var receivedError: NSError?

    func didReceiveError(sender: ErrorReportable, error: NSError) {
        receivedError = error
    }
}
