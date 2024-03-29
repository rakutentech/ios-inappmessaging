import Foundation
import Quick
import Nimble
@testable import RInAppMessaging

class CustomEventSpec: QuickSpec {
    override func spec() {
        describe("CustomEvent") {
            let customAttributes = [CustomAttribute(withKeyName: "Key1", withBoolValue: false),
                                    CustomAttribute(withKeyName: "Key2", withDoubleValue: 3),
                                    CustomAttribute(withKeyName: "Key3", withIntValue: 1)]
            let customEvent = CustomEvent(withName: "Test", withCustomAttributes: customAttributes, timestamp: 60)

            context("CustomEvent.analyticsParameters") {
                it("will return dictionary value with analytics parameters") {
                    let expectedAttributesRep: [NSDictionary] = [["name": "key1", "value": false],
                                                                 ["name": "key2", "value": 3],
                                                                 ["name": "key3", "value": 1]]
                    expect(customEvent.analyticsParameters).toNot(beNil())
                    expect(customEvent.analyticsParameters["eventName"] as? String).to(equal("test"))
                    expect(customEvent.analyticsParameters["timestamp"] as? Int64).to(beGreaterThan(0))
                    expect(customEvent.analyticsParameters["customAttributes"] as? [NSDictionary]).to(equal(expectedAttributesRep))
                }
            }

            context("CustomEvent.getAttributeMap") {
                it("will return non nil dictionary value with CustomAttribute values") {
                    customEvent.customAttributes = customAttributes
                    expect(customEvent.getAttributeMap()?["key1"]?.name).to(equal("key1"))
                    expect(customEvent.getAttributeMap()?["key1"]?.value as? Bool).to(equal(false))
                    expect(customEvent.getAttributeMap()?["key2"]?.name).to(equal("key2"))
                    expect(customEvent.getAttributeMap()?["key2"]?.value as? Double).to(equal(3))
                    expect(customEvent.getAttributeMap()?["key3"]?.name).to(equal("key3"))
                    expect(customEvent.getAttributeMap()?["key3"]?.value as? Int).to(equal(1))
                }
                it("will return nil value when customAttributes values are nil") {
                    customEvent.customAttributes = nil
                    expect(customEvent.getAttributeMap()).to(beNil())
                }
            }

            context("CustomEvent.isEqual") {
                it("will return false since the object is not of type Event") {
                    let commonUtility = CommonUtility()
                    expect(customEvent.isEqual(commonUtility)).to(beFalse())
                }
                it("will return false since name of the objects are different") {
                    let event = CustomEvent(withName: "Custom", withCustomAttributes: customAttributes)
                    expect(customEvent.isEqual(event)).to(beFalse())
                }
                it("will return false since type and name of the object is different") {
                    let event = Event(type: .purchaseSuccessful, name: "PurchaseSuccessful")
                    expect(customEvent.isEqual(event)).to(beFalse())
                }
                it("will return false since the attributes are different") {
                    let customAttributes = [CustomAttribute(withKeyName: "customKey1", withBoolValue: true),
                                             CustomAttribute(withKeyName: "customkey2", withDoubleValue: 5)]
                    let event = CustomEvent(withName: customEvent.name, withCustomAttributes: customAttributes)
                    expect(customEvent.isEqual(event)).to(beFalse())
                }
                it("will return true since the type and name is equal") {
                    let event = CustomEvent(withName: customEvent.name, withCustomAttributes: customAttributes)
                    expect(customEvent.name.isEqual(event.name)).to(beTrue())
                }
            }
        }
    }
}
