import Quick
import Nimble
@testable import RInAppMessaging

class BackoffSpec: QuickSpec {
    override func spec() {
        describe("Backoff") {
            let initialValue: Int32 = 10000

            it("should increase the retry delay") {
                var retryMS: Int32 = initialValue
                retryMS.increaseBackOff()

                let expectedResult = initialValue.multipliedReportingOverflow(by: 2).partialValue
                expect(retryMS).to(equal(expectedResult))
            }

            it("should increase the retry delay with a randomized value") {
                var retryMS: Int32 = initialValue
                retryMS.increaseRandomizedBackoff()

                let expectedResult = initialValue.multipliedReportingOverflow(by: 2).partialValue
                expect(retryMS >= expectedResult + (Constants.Retry.TooManyRequestsError.backOffLowerBoundInSecond * 1000)).to(beTrue())
                expect(retryMS <= expectedResult + (Constants.Retry.TooManyRequestsError.backOffUpperBoundInSecond * 1000)).to(beTrue())
            }
        }
    }
}
