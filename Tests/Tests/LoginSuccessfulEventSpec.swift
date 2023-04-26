import Foundation
import Quick
import Nimble
@testable import RInAppMessaging

class LoginSuccessfulEventSpec: QuickSpec {
    override func spec() {
        describe("LoginSuccessfulEvent") {
            let loginSuccessfulEvent = LoginSuccessfulEvent()

            context("LoginSuccessfulEvent.analyticsParameters") {
                it("will return dictionary with eventName and timestamp values") {
                    expect(loginSuccessfulEvent.analyticsParameters).toNot(beNil())
                    expect(loginSuccessfulEvent.analyticsParameters["eventName"] as? String).to(equal("login_successful"))
                    expect(loginSuccessfulEvent.analyticsParameters["timestamp"] as? Int64).to(beGreaterThan(0))
                }
            }

            context("LoginSuccessfulEvent.init(timestamp:)") {
                it("will return the timestamp value") {
                    let newEvent = LoginSuccessfulEvent(timestamp: 30)
                    expect(newEvent.timestamp).to(equal(30))
                }
            }
        }
    }
}
