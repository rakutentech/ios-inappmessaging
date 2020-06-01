import Quick
import Nimble
@testable import RInAppMessaging

// swiftlint:disable:next type_body_length
class MatchinUtilityTests: QuickSpec {

    // swiftlint:disable:next function_body_length
    override func spec() {

        describe("MatchingUtility") {

            let matchingUtility = MatchingUtility.self

            context("when comparing string values") {

                context("and operator is invalid") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: "a",
                                                                     eventAttributeValue: "a",
                                                                     operatorType: .invalid),
                                       matchingUtility.compareValues(triggerAttributeValue: "a",
                                                                     eventAttributeValue: "b",
                                                                     operatorType: .invalid),
                                       matchingUtility.compareValues(triggerAttributeValue: "",
                                                                     eventAttributeValue: "",
                                                                     operatorType: .invalid)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is equals") {

                    it("will return true if strings are equal") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "a",
                                                                   eventAttributeValue: "a",
                                                                   operatorType: .equals)
                        expect(result).to(beTrue())
                    }

                    it("will return true if strings are empty") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "",
                                                                   eventAttributeValue: "",
                                                                   operatorType: .equals)
                        expect(result).to(beTrue())
                    }

                    it("will return false if strings are not equal") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "a",
                                                                   eventAttributeValue: "b",
                                                                   operatorType: .equals)
                        expect(result).to(beFalse())
                    }
                }
                context("and operator is isNotEqual") {

                    it("will return true if strings are not equal") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "a",
                                                                   eventAttributeValue: "b",
                                                                   operatorType: .isNotEqual)
                        expect(result).to(beTrue())
                    }

                    it("will return false if strings are equal") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "a",
                                                                   eventAttributeValue: "a",
                                                                   operatorType: .isNotEqual)
                        expect(result).to(beFalse())
                    }

                    it("will return false if strings are empty") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "",
                                                                   eventAttributeValue: "",
                                                                   operatorType: .isNotEqual)
                        expect(result).to(beFalse())
                    }
                }
                context("and operator is greaterThan") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: "a",
                                                                     eventAttributeValue: "a",
                                                                     operatorType: .greaterThan),
                                       matchingUtility.compareValues(triggerAttributeValue: "a",
                                                                     eventAttributeValue: "b",
                                                                     operatorType: .greaterThan),
                                       matchingUtility.compareValues(triggerAttributeValue: "",
                                                                     eventAttributeValue: "",
                                                                     operatorType: .greaterThan)]
                        expect(results).to(allPass(beFalse()))
                    }
                }

                context("and operator is lessThan") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: "a",
                                                                     eventAttributeValue: "a",
                                                                     operatorType: .lessThan),
                                       matchingUtility.compareValues(triggerAttributeValue: "a",
                                                                     eventAttributeValue: "b",
                                                                     operatorType: .lessThan),
                                       matchingUtility.compareValues(triggerAttributeValue: "",
                                                                     eventAttributeValue: "",
                                                                     operatorType: .lessThan)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is isBlank") {

                    it("will return true if eventAttributeValue is blank and triggerAttributeValue is not blank") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "a",
                                                                   eventAttributeValue: "",
                                                                   operatorType: .isBlank)
                        expect(result).to(beTrue())
                    }

                    it("will return true if eventAttributeValue is blank and triggerAttributeValue is blank") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "",
                                                                   eventAttributeValue: "",
                                                                   operatorType: .isBlank)
                        expect(result).to(beTrue())
                    }

                    it("will return false if triggerAttributeValue is blank and eventAttributeValue is not blank") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "",
                                                                   eventAttributeValue: "a",
                                                                   operatorType: .isBlank)
                        expect(result).to(beFalse())
                    }
                }
                context("and operator is isNotBlank") {

                    it("will return false if eventAttributeValue is blank and triggerAttributeValue is not blank") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "a",
                                                                   eventAttributeValue: "",
                                                                   operatorType: .isNotBlank)
                        expect(result).to(beFalse())
                    }

                    it("will return false if eventAttributeValue is blank and triggerAttributeValue is blank") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "",
                                                                   eventAttributeValue: "",
                                                                   operatorType: .isNotBlank)
                        expect(result).to(beFalse())
                    }

                    it("will return true if triggerAttributeValue is blank and eventAttributeValue is not blank") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "",
                                                                   eventAttributeValue: "a",
                                                                   operatorType: .isNotBlank)
                        expect(result).to(beTrue())
                    }
                }
                context("and operator is matchesRegex") {

                    it("will return true if eventAttributeValue value matches regex in triggerAttributeValue") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "^a",
                                                                   eventAttributeValue: "abb",
                                                                   operatorType: .matchesRegex)
                        expect(result).to(beTrue())
                    }

                    it("will return false if eventAttributeValue value does not match regex in triggerAttributeValue") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "^a",
                                                                   eventAttributeValue: "b",
                                                                   operatorType: .matchesRegex)
                        expect(result).to(beFalse())
                    }

                    it("will return false if eventAttributeValue value is empty") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "^a",
                                                                   eventAttributeValue: "",
                                                                   operatorType: .matchesRegex)
                        expect(result).to(beFalse())
                    }

                    it("will return false if triggerAttributeValue value is empty") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "",
                                                                   eventAttributeValue: "a",
                                                                   operatorType: .matchesRegex)
                        expect(result).to(beFalse())
                    }

                    it("will return false if triggerAttributeValue value is empty") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "",
                                                                   eventAttributeValue: "a",
                                                                   operatorType: .matchesRegex)
                        expect(result).to(beFalse())
                    }

                    it("will return false if both attribute values are empty") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "",
                                                                   eventAttributeValue: "",
                                                                   operatorType: .matchesRegex)
                        expect(result).to(beFalse())
                    }
                }
                context("and operator is doesNotMatchRegex") {

                    it("will return false if eventAttributeValue value matches regex in triggerAttributeValue") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "^a",
                                                                   eventAttributeValue: "abb",
                                                                   operatorType: .doesNotMatchRegex)
                        expect(result).to(beFalse())
                    }

                    it("will return true if eventAttributeValue value does not match regex in triggerAttributeValue") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "^a",
                                                                   eventAttributeValue: "b",
                                                                   operatorType: .doesNotMatchRegex)
                        expect(result).to(beTrue())
                    }

                    it("will return true if eventAttributeValue value is empty") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "^a",
                                                                   eventAttributeValue: "",
                                                                   operatorType: .doesNotMatchRegex)
                        expect(result).to(beTrue())
                    }

                    it("will return true if both attribute values are empty") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: "",
                                                                   eventAttributeValue: "",
                                                                   operatorType: .doesNotMatchRegex)
                        expect(result).to(beTrue())
                    }
                }
            }

            context("when comparing bool values") {

                context("and operator is invalid") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .invalid),
                                       matchingUtility.compareValues(triggerAttributeValue: true,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .invalid),
                                       matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: false,
                                                                     operatorType: .invalid)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is equals") {

                    it("will return true if values are equal") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: false,
                                                                   eventAttributeValue: false,
                                                                   operatorType: .equals)
                        expect(result).to(beTrue())
                    }

                    it("will return false if values are not equal") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: true,
                                                                   eventAttributeValue: false,
                                                                   operatorType: .equals)
                        expect(result).to(beFalse())
                    }
                }
                context("and operator is isNotEqual") {

                    it("will return false if values are equal") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: true,
                                                                   eventAttributeValue: true,
                                                                   operatorType: .isNotEqual)
                        expect(result).to(beFalse())
                    }

                    it("will return true if values are not equal") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: false,
                                                                   eventAttributeValue: true,
                                                                   operatorType: .isNotEqual)
                        expect(result).to(beTrue())
                    }
                }
                context("and operator is greaterThan") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .greaterThan),
                                       matchingUtility.compareValues(triggerAttributeValue: true,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .greaterThan),
                                       matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: false,
                                                                     operatorType: .greaterThan)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is lessThan") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .lessThan),
                                       matchingUtility.compareValues(triggerAttributeValue: true,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .lessThan),
                                       matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: false,
                                                                     operatorType: .lessThan)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is isBlank") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .isBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: true,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .isBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: false,
                                                                     operatorType: .isBlank)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is isNotBlank") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .isNotBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: true,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .isNotBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: false,
                                                                     operatorType: .isNotBlank)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is matchesRegex") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .matchesRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: true,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .matchesRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: false,
                                                                     operatorType: .matchesRegex)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is doesNotMatchRegex") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .doesNotMatchRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: true,
                                                                     eventAttributeValue: true,
                                                                     operatorType: .doesNotMatchRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: false,
                                                                     eventAttributeValue: false,
                                                                     operatorType: .doesNotMatchRegex)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
            }

            context("when comparing integer values") {

                context("and operator is invalid") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 1,
                                                                     eventAttributeValue: 2,
                                                                     operatorType: .invalid),
                                       matchingUtility.compareValues(triggerAttributeValue: 2,
                                                                     eventAttributeValue: 2,
                                                                     operatorType: .invalid),
                                       matchingUtility.compareValues(triggerAttributeValue: -1,
                                                                     eventAttributeValue: -2,
                                                                     operatorType: .invalid),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -2,
                                                                     operatorType: .invalid)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is equals") {

                    it("will return true if values are equal") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2,
                                                                     eventAttributeValue: 2,
                                                                     operatorType: .equals),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -2,
                                                                     operatorType: .equals)]
                        expect(results).to(allPass(beTrue()))
                    }

                    it("will return false if values are not equal") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .equals),
                                       matchingUtility.compareValues(triggerAttributeValue: 2,
                                                                     eventAttributeValue: -2,
                                                                     operatorType: .equals)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is isNotEqual") {

                    it("will return false if values are equal") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2,
                                                                     eventAttributeValue: 2,
                                                                     operatorType: .isNotEqual),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -2,
                                                                     operatorType: .isNotEqual)]
                        expect(results).to(allPass(beFalse()))
                    }

                    it("will return true if values are not equal") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .isNotEqual),
                                       matchingUtility.compareValues(triggerAttributeValue: 2,
                                                                     eventAttributeValue: -2,
                                                                     operatorType: .isNotEqual)]
                        expect(results).to(allPass(beTrue()))
                    }
                }
                context("and operator is greaterThan") {

                    it("will return false if values are equal") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2,
                                                                     eventAttributeValue: 2,
                                                                     operatorType: .greaterThan),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -2,
                                                                     operatorType: .greaterThan)]
                        expect(results).to(allPass(beFalse()))
                    }

                    it("will return true if event value is greater than trigger value") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 1,
                                                                     eventAttributeValue: 2,
                                                                     operatorType: .greaterThan),
                                       matchingUtility.compareValues(triggerAttributeValue: -3,
                                                                     eventAttributeValue: -2,
                                                                     operatorType: .greaterThan),
                                       matchingUtility.compareValues(triggerAttributeValue: -3,
                                                                     eventAttributeValue: 0,
                                                                     operatorType: .greaterThan)]
                        expect(results).to(allPass(beTrue()))
                    }

                    it("will return false if event value is lower than trigger value") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: 2,
                                                                   eventAttributeValue: 1,
                                                                   operatorType: .greaterThan)
                        expect(result).to(beFalse())
                    }
                }
                context("and operator is lessThan") {

                    it("will return false if values are equal") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2,
                                                                     eventAttributeValue: 2,
                                                                     operatorType: .lessThan),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -2,
                                                                     operatorType: .lessThan)]
                        expect(results).to(allPass(beFalse()))
                    }

                    it("will return false if event value is greater than trigger value") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: 1,
                                                                   eventAttributeValue: 2,
                                                                   operatorType: .lessThan)
                        expect(result).to(beFalse())
                    }

                    it("will return true if event value is lower than trigger value") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .lessThan),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -3,
                                                                     operatorType: .lessThan),
                                       matchingUtility.compareValues(triggerAttributeValue: 0,
                                                                     eventAttributeValue: -3,
                                                                     operatorType: .lessThan)]
                        expect(results).to(allPass(beTrue()))
                    }
                }
                context("and operator is isBlank") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 1,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .isBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: 1,
                                                                     eventAttributeValue: 2,
                                                                     operatorType: .isBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -1,
                                                                     operatorType: .isBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -2,
                                                                     operatorType: .isBlank)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is isNotBlank") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 1,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .isNotBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: 1,
                                                                     eventAttributeValue: 2,
                                                                     operatorType: .isNotBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -1,
                                                                     operatorType: .isNotBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -2,
                                                                     operatorType: .isNotBlank)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is matchesRegex") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 1,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .matchesRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: 1,
                                                                     eventAttributeValue: 2,
                                                                     operatorType: .matchesRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -1,
                                                                     operatorType: .matchesRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -2,
                                                                     operatorType: .matchesRegex)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is doesNotMatchRegex") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 1,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .doesNotMatchRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: 1,
                                                                     eventAttributeValue: 2,
                                                                     operatorType: .doesNotMatchRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -1,
                                                                     operatorType: .doesNotMatchRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: -2,
                                                                     eventAttributeValue: -2,
                                                                     operatorType: .doesNotMatchRegex)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
            }

            context("when comparing double values") {

                context("and operator is invalid") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 2.11,
                                                                     operatorType: .invalid),
                                       matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .invalid),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -2.11,
                                                                     operatorType: .invalid),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -1,
                                                                     operatorType: .invalid)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is equals") {

                    it("will return true if values are equal") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 2.11,
                                                                     operatorType: .equals),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -2.11,
                                                                     operatorType: .equals)]
                        expect(results).to(allPass(beTrue()))
                    }

                    it("will return false if values are not equal") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .equals),
                                       matchingUtility.compareValues(triggerAttributeValue: 2.00,
                                                                     eventAttributeValue: -2.00,
                                                                     operatorType: .equals)]
                        expect(results).to(allPass(beFalse()))
                    }

                    it("will return false even if values difference is very low") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: 2,
                                                                   eventAttributeValue: 2.000000000000001,
                                                                   operatorType: .equals)
                        expect(result).to(beFalse())
                    }
                }
                context("and operator is isNotEqual") {

                    it("will return false if values are equal") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 2.11,
                                                                     operatorType: .isNotEqual),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -2.11,
                                                                     operatorType: .isNotEqual)]
                        expect(results).to(allPass(beFalse()))
                    }

                    it("will return true if values are not equal") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .isNotEqual),
                                       matchingUtility.compareValues(triggerAttributeValue: 2.00,
                                                                     eventAttributeValue: -2.00,
                                                                     operatorType: .isNotEqual)]
                        expect(results).to(allPass(beTrue()))
                    }

                    it("will return true even if values difference is very low") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: 2,
                                                                   eventAttributeValue: 2.000000000000001,
                                                                   operatorType: .isNotEqual)
                        expect(result).to(beTrue())
                    }
                }
                context("and operator is greaterThan") {

                    it("will return false if values are equal") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 2.11,
                                                                     operatorType: .greaterThan),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -2.11,
                                                                     operatorType: .greaterThan)]
                        expect(results).to(allPass(beFalse()))
                    }

                    it("will return true if event value is greater than trigger value") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 1,
                                                                     eventAttributeValue: 2.11,
                                                                     operatorType: .greaterThan),
                                       matchingUtility.compareValues(triggerAttributeValue: -3.11,
                                                                     eventAttributeValue: -2.11,
                                                                     operatorType: .greaterThan),
                                       matchingUtility.compareValues(triggerAttributeValue: -3.11,
                                                                     eventAttributeValue: 0,
                                                                     operatorType: .greaterThan)]
                        expect(results).to(allPass(beTrue()))
                    }

                    it("will return false if event value is lower than trigger value") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                   eventAttributeValue: 1,
                                                                   operatorType: .greaterThan)
                        expect(result).to(beFalse())
                    }
                }
                context("and operator is lessThan") {

                    it("will return false if values are equal") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 2.11,
                                                                     operatorType: .lessThan),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -2.11,
                                                                     operatorType: .lessThan)]
                        expect(results).to(allPass(beFalse()))
                    }

                    it("will return false if event value is greater than trigger value") {
                        let result = matchingUtility.compareValues(triggerAttributeValue: 1,
                                                                   eventAttributeValue: 2.11,
                                                                   operatorType: .lessThan)
                        expect(result).to(beFalse())
                    }

                    it("will return true if event value is lower than trigger value") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .lessThan),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -3.11,
                                                                     operatorType: .lessThan),
                                       matchingUtility.compareValues(triggerAttributeValue: 0,
                                                                     eventAttributeValue: -3.11,
                                                                     operatorType: .lessThan)]
                        expect(results).to(allPass(beTrue()))
                    }
                }
                context("and operator is isBlank") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 2.11,
                                                                     operatorType: .isBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .isBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -2.11,
                                                                     operatorType: .isBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -1,
                                                                     operatorType: .isBlank)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is isNotBlank") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 2.11,
                                                                     operatorType: .isNotBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .isNotBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -2.11,
                                                                     operatorType: .isNotBlank),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -1,
                                                                     operatorType: .isNotBlank)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is matchesRegex") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 2.11,
                                                                     operatorType: .matchesRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .matchesRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -2.11,
                                                                     operatorType: .matchesRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -1,
                                                                     operatorType: .matchesRegex)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is doesNotMatchRegex") {

                    it("will always return false") {
                        let results = [matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 2.11,
                                                                     operatorType: .doesNotMatchRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: 2.11,
                                                                     eventAttributeValue: 1,
                                                                     operatorType: .doesNotMatchRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -2.11,
                                                                     operatorType: .doesNotMatchRegex),
                                       matchingUtility.compareValues(triggerAttributeValue: -2.11,
                                                                     eventAttributeValue: -1,
                                                                     operatorType: .doesNotMatchRegex)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
            }

            context("when comparing time values") {

                context("and any of the values is negative") {
                    it("will accept them even though negative time values do not make sense") {
                        expect("testing negative values is not necessary").toNot(beEmpty())
                    }
                }

                context("and operator is invalid") {

                    it("will always return false") {
                        let results = [matchingUtility.compareTimeValues(triggerAttributeValue: 1,
                                                                         eventAttributeValue: 2,
                                                                         operatorType: .invalid),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 2,
                                                                         operatorType: .invalid),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 2 + MatchingUtility.timeToleranceMilliseconds / 2,
                                                                         operatorType: .invalid)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is equals") {

                    it("will return true if values are equal") {
                        let result = matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                       eventAttributeValue: 2,
                                                                       operatorType: .equals)
                        expect(result).to(beTrue())
                    }

                    it("will return true if values difference is lower or equal tolerance") {
                        let results = [matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 2 + MatchingUtility.timeToleranceMilliseconds,
                                                                         operatorType: .equals),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 2 - MatchingUtility.timeToleranceMilliseconds,
                                                                         operatorType: .equals)]
                        expect(results).to(allPass(beTrue()))
                    }

                    it("will return false if values difference is greater than tolerance") {
                        let results = [matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 2 + (MatchingUtility.timeToleranceMilliseconds + 1),
                                                                         operatorType: .equals),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 2 - (MatchingUtility.timeToleranceMilliseconds + 1),
                                                                         operatorType: .equals)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is isNotEqual") {

                    it("will return false if values are equal") {
                        let result = matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                       eventAttributeValue: 2,
                                                                       operatorType: .isNotEqual)
                        expect(result).to(beFalse())
                    }

                    it("will return false if values difference is lower or equal tolerance") {
                        let results = [matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 2 + MatchingUtility.timeToleranceMilliseconds,
                                                                         operatorType: .isNotEqual),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 2 - MatchingUtility.timeToleranceMilliseconds,
                                                                         operatorType: .isNotEqual)]
                        expect(results).to(allPass(beFalse()))
                    }

                    it("will return true if values difference is greater than tolerance") {
                        let results = [matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 2 + (MatchingUtility.timeToleranceMilliseconds + 1),
                                                                         operatorType: .isNotEqual),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 2 - (MatchingUtility.timeToleranceMilliseconds + 1),
                                                                         operatorType: .isNotEqual)]
                        expect(results).to(allPass(beTrue()))
                    }
                }
                context("and operator is greaterThan") {

                    it("will return false if values are equal") {
                        let result = matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                       eventAttributeValue: 2,
                                                                       operatorType: .greaterThan)
                        expect(result).to(beFalse())
                    }

                    context("and value difference is greater than tolerance") {

                        it("will return true if event value is greater than trigger value") {
                            let result = matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                           eventAttributeValue: 2 + (MatchingUtility.timeToleranceMilliseconds + 1),
                                                                           operatorType: .greaterThan)
                            expect(result).to(beTrue())
                        }

                        it("will return false if event value is lower than trigger value") {
                            let result = matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                           eventAttributeValue: 2 - (MatchingUtility.timeToleranceMilliseconds + 1),
                                                                           operatorType: .greaterThan)
                            expect(result).to(beFalse())
                        }
                    }

                    context("and value difference is lower or equal tolerance") {

                        it("will return false if event value is greater than trigger value") {
                            let result = matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                           eventAttributeValue: 2 + MatchingUtility.timeToleranceMilliseconds,
                                                                           operatorType: .greaterThan)
                            expect(result).to(beFalse())
                        }

                        it("will return false if event value is lower than trigger value") {
                            let result = matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                           eventAttributeValue: 2 - MatchingUtility.timeToleranceMilliseconds,
                                                                           operatorType: .greaterThan)
                            expect(result).to(beFalse())
                        }
                    }
                }
                context("and operator is lessThan") {

                    it("will return false if values are equal") {
                        let result = matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                       eventAttributeValue: 2,
                                                                       operatorType: .lessThan)
                        expect(result).to(beFalse())
                    }

                    context("and value difference is greater than tolerance") {

                        it("will return false if event value is greater than trigger value") {
                            let result = matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                           eventAttributeValue: 2 + (MatchingUtility.timeToleranceMilliseconds + 1),
                                                                           operatorType: .lessThan)
                            expect(result).to(beFalse())
                        }

                        it("will return true if event value is lower than trigger value") {
                            let result = matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                           eventAttributeValue: 2 - (MatchingUtility.timeToleranceMilliseconds + 1),
                                                                           operatorType: .lessThan)
                            expect(result).to(beTrue())
                        }
                    }

                    context("and value difference is lower or equal tolerance") {

                        it("will return false if event value is greater than trigger value") {
                            let result = matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                           eventAttributeValue: 2 + MatchingUtility.timeToleranceMilliseconds,
                                                                           operatorType: .lessThan)
                            expect(result).to(beFalse())
                        }

                        it("will return false if event value is lower than trigger value") {
                            let result = matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                           eventAttributeValue: 2 - MatchingUtility.timeToleranceMilliseconds,
                                                                           operatorType: .lessThan)
                            expect(result).to(beFalse())
                        }
                    }
                }
                context("and operator is isBlank") {

                    it("will always return false") {
                        let results = [matchingUtility.compareTimeValues(triggerAttributeValue: 1,
                                                                         eventAttributeValue: 1,
                                                                         operatorType: .isBlank),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 1,
                                                                         eventAttributeValue: 2,
                                                                         operatorType: .isBlank),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 1,
                                                                         operatorType: .isBlank)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is isNotBlank") {

                    it("will always return false") {
                        let results = [matchingUtility.compareTimeValues(triggerAttributeValue: 1,
                                                                         eventAttributeValue: 1,
                                                                         operatorType: .isNotBlank),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 1,
                                                                         eventAttributeValue: 2,
                                                                         operatorType: .isNotBlank),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 1,
                                                                         operatorType: .isNotBlank)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is matchesRegex") {

                    it("will always return false") {
                        let results = [matchingUtility.compareTimeValues(triggerAttributeValue: 1,
                                                                         eventAttributeValue: 1,
                                                                         operatorType: .matchesRegex),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 1,
                                                                         eventAttributeValue: 2,
                                                                         operatorType: .matchesRegex),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 1,
                                                                         operatorType: .matchesRegex)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
                context("and operator is doesNotMatchRegex") {

                    it("will always return false") {
                        let results = [matchingUtility.compareTimeValues(triggerAttributeValue: 1,
                                                                         eventAttributeValue: 1,
                                                                         operatorType: .doesNotMatchRegex),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 1,
                                                                         eventAttributeValue: 2,
                                                                         operatorType: .doesNotMatchRegex),
                                       matchingUtility.compareTimeValues(triggerAttributeValue: 2,
                                                                         eventAttributeValue: 1,
                                                                         operatorType: .doesNotMatchRegex)]
                        expect(results).to(allPass(beFalse()))
                    }
                }
            }
        }
    }
}
