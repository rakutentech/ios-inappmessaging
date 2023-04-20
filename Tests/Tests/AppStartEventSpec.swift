import Foundation
import Quick
import Nimble
@testable import RInAppMessaging

class AppStartEventSpec: QuickSpec {
    override func spec() {
        describe("AppStartEvent") {
            let appStartEvent = AppStartEvent.init(timestamp: 50)
            context("AppStartEvent.analyticsParameters") {
                it("will return dictionary with eventName and timestamp values") {
                    expect(appStartEvent.analyticsParameters).toNot(beNil())
                    expect(appStartEvent.analyticsParameters).to(beAKindOf([String: Any].self))
                }
            }
        }
    }
}
