import Quick
import Nimble
@testable import RInAppMessaging
import CoreFoundation

class CustomEventSpec: QuickSpec {
    override func spec() {
        describe("CustomEvent") {
            let customAttributes =  [CustomAttribute(withKeyName: "Key1", withBoolValue: false),
                                     CustomAttribute(withKeyName: "Key2", withDoubleValue: 3),
                                     CustomAttribute(withKeyName: "Key3", withIntValue: 1)]
            let customEvent = CustomEvent(withName: "Test4", withCustomAttributes: customAttributes)
            context("CustomEvent.analyticsParameters") {
                it("will return non nil dictionary value") {
                    expect(customEvent.analyticsParameters).toNot(beNil())
                }
            }
            context("CustomEvent.getAttributeMap") {
                it("will return non nil dictionary value") {
                    customEvent.customAttributes = customAttributes
                    expect(customEvent.getAttributeMap()).toNot(beNil())
                }
                it("will return nil value") {
                    customEvent.customAttributes = nil
                    expect(customEvent.getAttributeMap()).to(beNil())
                }
            }
            context("CustomEvent.isEqual") {
                it("will return false since the object is not of type Event") {
                    let commonUtility = CommonUtility()
                    expect(customEvent.isEqual(commonUtility)).to(beFalse())
                }
                it("will return false since the type and name of the object is different") {
                    let newEvent = CustomEvent(withName: "Custom", withCustomAttributes: customAttributes)
                    expect(customEvent.isEqual(newEvent)).to(beFalse())
                }
                it("will return true since the type and name is equal") {
                    let newEvent2 = CustomEvent(withName: "Test4", withCustomAttributes: customAttributes)
                    expect(customEvent.name.isEqual(newEvent2.name)).to(beTrue())
                }
            }
            context("CustomEvent.init") {
                it("will return false since the super object is not equal") {
                let custom = CustomEvent.init(withName: "customEvent", withCustomAttributes: customAttributes, timestamp: 60)
                    expect(custom.timestamp).to(equal(60))
                }
            }
        }
    }
}
