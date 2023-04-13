import Quick
import Nimble
@testable import RInAppMessaging
import CoreFoundation

class AppStartEventSpec: QuickSpec {
    override func spec() {
        describe("AppStartEvent") {
            let appStartEvent = AppStartEvent()
            context("AppStartEvent.analyticsParameters") {
                it("will return dictionary with eventName and timestamp values") {
                    if let eventName = appStartEvent.analyticsParameters["eventName"] as? String {
                        expect(eventName).to(equal("app_start"))
                    }
                    expect(appStartEvent.analyticsParameters["timestamp"]).toNot(beNil())
                }
            }
            context("AppStartEvent.init(timestamp:)") {
                it("will return the timestamp value") {
                    let appStart = AppStartEvent.init(timestamp: 50)
                    expect(appStart.timestamp).to(equal(50))
                }
            }
        }
    }
}
