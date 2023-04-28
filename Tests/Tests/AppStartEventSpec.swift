import Foundation
import Quick
import Nimble
@testable import RInAppMessaging

class AppStartEventSpec: QuickSpec {
    override func spec() {
        describe("AppStartEvent") {
            let appStartEvent = AppStartEvent(timestamp: 50)
            context("AppStartEvent.analyticsParameters") {
                it("will return dictionary with eventName and timestamp values") {
                    expect(appStartEvent.analyticsParameters).toNot(beNil())
                    expect(appStartEvent.analyticsParameters["eventName"] as? String).to(equal("app_start"))
                    expect(appStartEvent.analyticsParameters["timestamp"] as? Int64).to(beGreaterThan(0))
                }
            }
        }
    }
}
