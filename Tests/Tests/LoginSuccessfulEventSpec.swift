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
                    if let eventName = loginSuccessfulEvent.analyticsParameters["eventName"] as? String {
                        expect(eventName).to(equal("login_successful"))
                    }
                    expect(loginSuccessfulEvent.analyticsParameters["timestamp"]).toNot(beNil())
                }
            }
            context("LoginSuccessfulEvent.init(timestamp:)") {
                it("will return the timestamp value") {
                    let newEvent = LoginSuccessfulEvent.init(timestamp: 30)
                    expect(newEvent.timestamp).to(equal(30))
                }
            }
        }
    }
}
