import Quick
import Nimble
@testable import RInAppMessaging

class EventTypeSpec: QuickSpec {

    override func spec() {

        describe("EventType") {

            context("when accessing name") {

                it("should return invalid") {
                    let type = EventType.invalid
                    expect(type.name).to(equal("invalid"))
                }

                it("should return app_start") {
                    let type = EventType.appStart
                    expect(type.name).to(equal("app_start"))
                }

                it("should return login_successful") {
                    let type = EventType.loginSuccessful
                    expect(type.name).to(equal("login_successful"))
                }

                it("should return purchase_successful") {
                    let type = EventType.purchaseSuccessful
                    expect(type.name).to(equal("purchase_successful"))
                }

                it("should return custom") {
                    let type = EventType.custom
                    expect(type.name).to(equal("custom"))
                }

                it("should return view_appeared") {
                    let type = EventType.viewAppeared
                    expect(type.name).to(equal("view_appeared"))
                }
            }
        }
    }
}
