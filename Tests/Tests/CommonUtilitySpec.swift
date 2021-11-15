import Foundation
import Quick
import Nimble
@testable import RInAppMessaging

class CommonUtilitySpec: QuickSpec {

    override func spec() {
        describe("CommonUtility") {

            context("CommonUtility.lock") {

                it("will lock provided resource for the time of operation") {
                    let lockableObject = LockableTestObject()
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
                        lockableObject.append(2)
                    })
                    CommonUtility.lock(resourcesIn: [lockableObject]) {
                        sleep(2)
                        lockableObject.append(1)
                    }

                    expect(lockableObject.resource.get()).toEventually(equal([1, 2]))
                }
            }

            context("CommonUtility.convertDataToDictionary") {

                let validJSON = """
                    {
                        "campaignId": "id1",
                        "maxImpressions": 1,
                        "isTest": false,
                        "triggers": [{
                                        "eventName": "event"
                                    }]
                    }
                """

                let corruptedJSON = """
                    {
                        "campaignId": "id1",
                """

                let invalidJSON = "@@@"
                let arrayJSON = """
                    ["element"]
                """

                it("will return dictionary value for valid json data") {
                    let data = validJSON.data(using: .utf8)!
                    let result = CommonUtility.convertDataToDictionary(data)
                    expect(result).toNot(beNil())
                    expect(result).to(beAKindOf([String: Any].self))
                }

                it("will return properly populated dictionary based on json data") {
                    let data = validJSON.data(using: .utf8)!
                    let result = CommonUtility.convertDataToDictionary(data)

                    expect(result?["campaignId"] as? String).to(equal("id1"))
                    expect(result?["maxImpressions"] as? Int).to(equal(1))
                    expect(result?["isTest"] as? Bool).to(equal(false))

                    let arrayValue = result?["triggers"] as? [[String: String]]
                    expect(arrayValue).toNot(beNil())
                    expect(arrayValue?.first?["eventName"]).to(equal("event"))
                }

                it("will return empty dictionary for empty json data") {
                    let data = "{}".data(using: .utf8)!
                    let result = CommonUtility.convertDataToDictionary(data)
                    expect(result).toNot(beNil())
                }

                it("will return nil for corrupted json data") {
                    let data = corruptedJSON.data(using: .utf8)!
                    let result = CommonUtility.convertDataToDictionary(data)
                    expect(result).to(beNil())
                }

                it("will return nil for invalid json data") {
                    let data = invalidJSON.data(using: .utf8)!
                    let result = CommonUtility.convertDataToDictionary(data)
                    expect(result).to(beNil())
                }

                it("will return nil for array json data") {
                    let data = arrayJSON.data(using: .utf8)!
                    let result = CommonUtility.convertDataToDictionary(data)
                    expect(result).to(beNil())
                }

                it("will return nil for empty string data") {
                    let data = "".data(using: .utf8)!
                    let result = CommonUtility.convertDataToDictionary(data)
                    expect(result).to(beNil())
                }

                it("will return nil for empty data") {
                    let data = Data()
                    let result = CommonUtility.convertDataToDictionary(data)
                    expect(result).to(beNil())
                }
            }

            context("CommonUtility.convertAttributeObjectToCustomAttribute") {

                it("will return nil for invalid attribute type") {
                    let attribute = TriggerAttribute(name: "att", value: "val",
                                                     type: .invalid, operator: .invalid)
                    let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                    expect(result).to(beNil())
                }

                it("will succeed regardless of operator type") {
                    let attribute1 = TriggerAttribute(name: "att", value: "1",
                                                     type: .integer, operator: .invalid)
                    let attribute2 = TriggerAttribute(name: "att", value: "1",
                                                      type: .integer, operator: .greaterThan)
                    let attribute3 = TriggerAttribute(name: "att", value: "1",
                                                      type: .integer, operator: .isBlank)

                    expect(CommonUtility.convertAttributeObjectToCustomAttribute(attribute1))
                        .toNot(beNil())
                    expect(CommonUtility.convertAttributeObjectToCustomAttribute(attribute2))
                        .toNot(beNil())
                    expect(CommonUtility.convertAttributeObjectToCustomAttribute(attribute3))
                        .toNot(beNil())
                }

                context("when given attribute is string type") {

                    it("will return string value CustomAttribute for valid value") {
                        let attribute = TriggerAttribute(name: "att", value: "5",
                                                         type: .string, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result?.type).to(equal(.string))
                        expect(result?.value as? String).to(equal("5"))
                    }

                    it("will return string value CustomAttribute for empty value") {
                        let attribute = TriggerAttribute(name: "att", value: "",
                                                         type: .string, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result?.type).to(equal(.string))
                        expect(result?.value as? String).to(equal(""))
                    }
                }

                context("when given attribute is integer type") {

                    it("will return integer value CustomAttribute for valid value") {
                        let attribute = TriggerAttribute(name: "att", value: "-5",
                                                         type: .integer, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result?.type).to(equal(.integer))
                        expect(result?.value as? Int).to(equal(-5))
                    }

                    it("will return nil for double value") {
                        let attribute = TriggerAttribute(name: "att", value: "5.0",
                                                         type: .integer, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result).to(beNil())
                    }

                    it("will return nil for empty value") {
                        let attribute = TriggerAttribute(name: "att", value: "",
                                                         type: .integer, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result).to(beNil())
                    }

                    it("will return nil for invalid value") {
                        let attribute = TriggerAttribute(name: "att", value: "A",
                                                         type: .integer, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result).to(beNil())
                    }
                }

                context("when given attribute is boolean type") {

                    context("and value is valid") {

                        it("will return boolean value (true) CustomAttribute for 'true' value") {
                            let attribute = TriggerAttribute(name: "att", value: "true",
                                                             type: .boolean, operator: .invalid)
                            let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                            expect(result?.type).to(equal(.boolean))
                            expect(result?.value as? Bool).to(equal(true))
                        }

                        it("will return boolean value (true) CustomAttribute for 'TRUE' value") {
                            let attribute = TriggerAttribute(name: "att", value: "TRUE",
                                                             type: .boolean, operator: .invalid)
                            let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                            expect(result?.type).to(equal(.boolean))
                            expect(result?.value as? Bool).to(equal(true))
                        }

                        it("will return boolean value (true) CustomAttribute for integer value - 1") {
                            let attribute = TriggerAttribute(name: "att", value: "1",
                                                             type: .boolean, operator: .invalid)
                            let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                            expect(result?.type).to(equal(.boolean))
                            expect(result?.value as? Bool).to(equal(true))
                        }

                        it("will return boolean value (false) CustomAttribute for integer value - 0") {
                            let attribute = TriggerAttribute(name: "att", value: "0",
                                                             type: .boolean, operator: .invalid)
                            let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                            expect(result?.type).to(equal(.boolean))
                            expect(result?.value as? Bool).to(equal(false))
                        }
                    }

                    it("will return nil for integer value that is not 0 or 1") {
                        let attribute = TriggerAttribute(name: "att", value: "2",
                                                         type: .boolean, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result).to(beNil())
                    }

                    it("will return nil for empty value") {
                        let attribute = TriggerAttribute(name: "att", value: "",
                                                         type: .boolean, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result).to(beNil())
                    }

                    it("will return nil for invalid value") {
                        let attribute = TriggerAttribute(name: "att", value: "A",
                                                         type: .boolean, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result).to(beNil())
                    }
                }

                context("when given attribute is double type") {

                    context("and value is valid") {

                        it("will return double value CustomAttribute for floating point number value") {
                            let attribute = TriggerAttribute(name: "att", value: "-5.2",
                                                             type: .double, operator: .invalid)
                            let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                            expect(result?.type).to(equal(.double))
                            expect(result?.value as? Double).to(equal(-5.2))
                        }

                        it("will return double value CustomAttribute for integer value") {
                            let attribute = TriggerAttribute(name: "att", value: "-5",
                                                             type: .double, operator: .invalid)
                            let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                            expect(result?.type).to(equal(.double))
                            expect(result?.value as? Double).to(equal(-5.0))
                        }
                    }

                    it("will return nil for empty value") {
                        let attribute = TriggerAttribute(name: "att", value: "",
                                                         type: .double, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result).to(beNil())
                    }

                    it("will return nil for invalid value") {
                        let attribute = TriggerAttribute(name: "double", value: "A",
                                                         type: .double, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result).to(beNil())
                    }
                }

                context("when given attribute is timeInMilliseconds type") {

                    it("will return timeInMilliseconds value CustomAttribute for valid value") {
                        let attribute = TriggerAttribute(name: "att", value: "-5",
                                                         type: .timeInMilliseconds, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result?.type).to(equal(.timeInMilliseconds))
                        expect(result?.value as? Int).to(equal(-5))
                    }

                    it("will return nil for double value") {
                        let attribute = TriggerAttribute(name: "att", value: "5.0",
                                                         type: .timeInMilliseconds, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result).to(beNil())
                    }

                    it("will return nil for empty value") {
                        let attribute = TriggerAttribute(name: "att", value: "",
                                                         type: .timeInMilliseconds, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result).to(beNil())
                    }

                    it("will return nil for invalid value") {
                        let attribute = TriggerAttribute(name: "att", value: "A",
                                                         type: .timeInMilliseconds, operator: .invalid)
                        let result = CommonUtility.convertAttributeObjectToCustomAttribute(attribute)
                        expect(result).to(beNil())
                    }
                }
            }
        }
    }
}
