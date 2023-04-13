import Quick
import Nimble
@testable import RInAppMessaging

class EventSpec: QuickSpec {
    override func spec() {
        describe("Event") {
            let event = Event(type: .appStart, name: "appStart")

            context("Event.analyticsParameters") {
                it("will return an empty dictionary") {
                    expect(event.analyticsParameters.count).to(equal(0))
                }
            }
            context("Event.getAttributeMap") {
                it("will return nil") {
                    expect(event.getAttributeMap()).to(beNil())
                }
            }
            context("Event.isEqual") {
                it("will return false since the object is not of type Event") {
                    let commonUtility = CommonUtility()
                    expect(event.isEqual(commonUtility)).to(beFalse())
                }
                it("will return false since the type and name of the object is different") {
                    let newEvent = Event(type: .custom, name: "custom")
                    expect(event.isEqual(newEvent)).to(beFalse())
                }
                it("will return true since the type and name of the object is same") {
                    let newEvent2 = Event(type: .appStart, name: "appStart")
                    expect(event.isEqual(newEvent2)).to(beTrue())
                }
            }
        }
    }
}
