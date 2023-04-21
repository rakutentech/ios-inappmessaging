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
                    expect(appStartEvent.analyticsParameters["eventName"]).to(beAKindOf(String.self))
                    expect(appStartEvent.analyticsParameters["timestamp"]).to(beAKindOf(Int64.self))
                }
            }
        }
    }
}
