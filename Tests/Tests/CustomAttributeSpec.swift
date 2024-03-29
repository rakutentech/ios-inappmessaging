import Quick
import Nimble
@testable import RInAppMessaging

class CustomAttributeSpec: QuickSpec {

    override func spec() {

        describe("CustomAttribute") {
            context("when accessing name") {

                it("should return lowercased string for bool type") {
                    let att = CustomAttribute(withKeyName: "TeSt4", withBoolValue: false)
                    expect(att.name) == "test4"
                }

                it("should return lowercased string for int type") {
                    let att = CustomAttribute(withKeyName: "TeSt4", withIntValue: 5)
                    expect(att.name) == "test4"
                }

                it("should return lowercased string for double type") {
                    let att = CustomAttribute(withKeyName: "TeSt4", withDoubleValue: 2.1)
                    expect(att.name) == "test4"
                }

                it("should return lowercased string for time type") {
                    let att = CustomAttribute(withKeyName: "TeSt4", withTimeInMilliValue: 100)
                    expect(att.name) == "test4"
                }

                it("should return lowercased string for string type") {
                    let att = CustomAttribute(withKeyName: "TeSt4", withStringValue: "AAA")
                    expect(att.name) == "test4"
                }
            }

            context("when accessing value") {

                it("should return lowercased string value") {
                    let att = CustomAttribute(withKeyName: "test", withStringValue: "TeSt4")
                    expect(att.value as? String) == "test4"
                }
            }

            context("when accessing dictionary representation") {

                it("should return dictionary without type") {
                    let att = CustomAttribute(withKeyName: "test", withStringValue: "TeSt4")
                    expect(att.dictionaryRepresentation["type"]).to(beNil())
                }

                it("should return dictionary with name test") {
                    let att = CustomAttribute(withKeyName: "tEst", withStringValue: "test5")
                    let name = att.dictionaryRepresentation["name"] as? String
                    expect(name).to(equal("test"))
                }

                it("should return dictionary with value test5") {
                    let att = CustomAttribute(withKeyName: "test", withStringValue: "teSt5")
                    let value = att.dictionaryRepresentation["value"] as? String
                    expect(value).to(equal("test5"))
                }
            }

            context("when comparing objects") {

                it("will return false when names differ") {
                    let att1 = CustomAttribute(withKeyName: "1", withBoolValue: true)
                    let att2 = CustomAttribute(withKeyName: "2", withBoolValue: true)
                    expect(att1).toNot(equal(att2))
                }

                it("will return false when types differ") {
                    let att1 = CustomAttribute(withKeyName: "1", withBoolValue: true)
                    let att2 = CustomAttribute(withKeyName: "1", withStringValue: "abc")
                    expect(att1).toNot(equal(att2))
                }

                it("will return true when all fields match (bool)") {
                    let att1 = CustomAttribute(withKeyName: "1", withBoolValue: false)
                    let att2 = CustomAttribute(withKeyName: "1", withBoolValue: false)
                    expect(att1).to(equal(att2))
                }

                it("will return true when all fields match (string)") {
                    let att1 = CustomAttribute(withKeyName: "1", withStringValue: "abc")
                    let att2 = CustomAttribute(withKeyName: "1", withStringValue: "abc")
                    expect(att1).to(equal(att2))
                }

                it("will return true when all fields match (double)") {
                    let att1 = CustomAttribute(withKeyName: "1", withDoubleValue: 3.11)
                    let att2 = CustomAttribute(withKeyName: "1", withDoubleValue: 3.11)
                    expect(att1).to(equal(att2))
                }

                it("will return true when all fields match (int)") {
                    let att1 = CustomAttribute(withKeyName: "1", withIntValue: -1)
                    let att2 = CustomAttribute(withKeyName: "1", withIntValue: -1)
                    expect(att1).to(equal(att2))
                }

                it("will return true when all fields match (time)") {
                    let att1 = CustomAttribute(withKeyName: "1", withTimeInMilliValue: 133333)
                    let att2 = CustomAttribute(withKeyName: "1", withTimeInMilliValue: 133333)
                    expect(att1).to(equal(att2))
                }

                it("will return false when values differ (bool)") {
                    let att1 = CustomAttribute(withKeyName: "1", withBoolValue: false)
                    let att2 = CustomAttribute(withKeyName: "1", withBoolValue: true)
                    expect(att1).toNot(equal(att2))
                }

                it("will return false when values differ (string)") {
                    let att1 = CustomAttribute(withKeyName: "1", withStringValue: "abc")
                    let att2 = CustomAttribute(withKeyName: "1", withStringValue: "")
                    expect(att1).toNot(equal(att2))
                }

                it("will return false when values differ (double)") {
                    let att1 = CustomAttribute(withKeyName: "1", withDoubleValue: 3.11)
                    let att2 = CustomAttribute(withKeyName: "1", withDoubleValue: -3.11)
                    expect(att1).toNot(equal(att2))
                }

                it("will return false when values differ (int)") {
                    let att1 = CustomAttribute(withKeyName: "1", withIntValue: -1)
                    let att2 = CustomAttribute(withKeyName: "1", withIntValue: 1)
                    expect(att1).toNot(equal(att2))
                }

                it("will return false when values differ (time)") {
                    let att1 = CustomAttribute(withKeyName: "1", withTimeInMilliValue: 133333)
                    let att2 = CustomAttribute(withKeyName: "1", withTimeInMilliValue: 13333)
                    expect(att1).toNot(equal(att2))
                }

                it("will return false when object is not CustomAttribute") {
                    let att1 = CustomAttribute(withKeyName: "CustomAttribute", withStringValue: "value")
                    let att2 = "Not CustomAttribute"
                    expect(att1.isEqual(att2)).to(beFalse())
                }

                it("will return false when objectValue is not NSObject") {
                    let att1 = CustomAttribute(withKeyName: "CustomAttribute", withStringValue: "value")
                    var att2 = CustomAttribute(withKeyName: "CustomAttribute", withInvalid: ActionType.invalid)
                    expect(att1.isEqual(att2)).to(beFalse())
                }
            }
        }
    }
}
