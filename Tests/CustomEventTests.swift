import Quick
import Nimble
@testable import RInAppMessaging

/// Tests for campaign validation logic when provided with different custom events
class CustomEventsTest: QuickSpec {
//swiftlint:disable:previous type_body_length

    //swiftlint:disable:next function_body_length
    override func spec() {

        var campaignsValidator: CampaignsValidator!
        var campaignRepository: CampaignRepository!
        var eventMatcher: EventMatcher!
        var validatorHandler: ValidatorHandler!

        beforeEach {
            campaignRepository = CampaignRepository()
            eventMatcher = EventMatcher(campaignRepository: campaignRepository)
            campaignsValidator = CampaignsValidator(
                campaignRepository: campaignRepository,
                eventMatcher: eventMatcher)
            validatorHandler = ValidatorHandler()
        }

        context("CampaignsValidator") {
            it("should accept a campaign that is matched using an custom event with a STRING type and equals operator") {
                let mockResponse = TestHelpers.MockResponse.stringTypeWithEqualsOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withStringValue: "notAttributeOneValue")
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withStringValue: "attributeOneValue")
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with a STRING type and isNotEqual operator") {
                let mockResponse = TestHelpers.MockResponse.stringTypeWithNotEqualsOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withStringValue: "attributeOneValue")
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withStringValue: "notAttributeOneValue")
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with an INTEGER type and equals operator") {
                let mockResponse = TestHelpers.MockResponse.intTypeWithEqualsOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withIntValue: 124)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withIntValue: 123)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with an INTEGER type and isNotEqual operator") {
                let mockResponse = TestHelpers.MockResponse.intTypeWithNotEqualsOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withIntValue: 123)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withIntValue: 124)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with an INTEGER type and greaterThan operator") {
                let mockResponse = TestHelpers.MockResponse.intTypeWithGreaterThanOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withIntValue: 122)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withIntValue: 124)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with an INTEGER type and lessThan operator") {
                let mockResponse = TestHelpers.MockResponse.intTypeWithLessThanOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withIntValue: 124)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withIntValue: 122)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with a DOUBLE type and equals operator") {
                let mockResponse = TestHelpers.MockResponse.doubleTypeWithEqualsOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withDoubleValue: 124.0)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withDoubleValue: 123.0)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with a DOUBLE type and isNotEqual operator") {
                let mockResponse = TestHelpers.MockResponse.doubleTypeWithNotEqualsOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withDoubleValue: 123.0)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withDoubleValue: 124.0)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with a DOUBLE type and greaterThan operator") {
                let mockResponse = TestHelpers.MockResponse.doubleTypeWithGreaterThanOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withDoubleValue: 122.0)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withDoubleValue: 124.0)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with a DOUBLE type and lessThan operator") {
                let mockResponse = TestHelpers.MockResponse.doubleTypeWithLessThanOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withDoubleValue: 124.0)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withDoubleValue: 122.0)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with a BOOL type and equals operator") {
                let mockResponse = TestHelpers.MockResponse.boolTypeWithEqualsOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withBoolValue: false)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withBoolValue: true)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with a BOOL type and isNotEqual operator") {
                let mockResponse = TestHelpers.MockResponse.boolTypeWithNotEqualOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withBoolValue: true)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withBoolValue: false)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with a time(int) type and equals operator") {
                let mockResponse = TestHelpers.MockResponse.timeTypeWithEqualsOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withTimeInMilliValue: 1)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withTimeInMilliValue: 1099)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with a time(int) type and isNotEqual operator") {
                let mockResponse = TestHelpers.MockResponse.timeTypeWithNotEqualsOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withTimeInMilliValue: 1099)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withTimeInMilliValue: 1)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with a time(int) type and greaterThan operator") {
                let mockResponse = TestHelpers.MockResponse.timeTypeWithGreaterThanOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withTimeInMilliValue: 1)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withTimeInMilliValue: 3000)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched using an custom event with a time(int) type and lessThan operator") {
                let mockResponse = TestHelpers.MockResponse.timeTypeWithLessThanOperator
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withTimeInMilliValue: 2200)
                    ]
                )
                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())

                let customEvent2 = CustomEvent(
                    withName: "testEvent",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "attributeOne", withTimeInMilliValue: 1)
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent2)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched even with a case-insensitive event name") {
                let mockResponse = TestHelpers.MockResponse.caseInsensitiveEventName
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "TESTEVENT",
                    withCustomAttributes: [
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should accept a campaign that is matched even with a case-insensitive attribute name") {
                let mockResponse = TestHelpers.MockResponse.caseInsensitiveAttributeName
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "TESTEVENT",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "AtTriButeone", withStringValue: "hi")
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(haveCount(1))
            }

            it("should not have a campaign because of case-sensitive attribute value mismatch") {
                let mockResponse = TestHelpers.MockResponse.caseSensitiveAttributeValue
                campaignRepository.syncWith(list: mockResponse.data, timestampMilliseconds: 0)

                let customEvent = CustomEvent(
                    withName: "TESTEVENT",
                    withCustomAttributes: [
                        CustomAttribute(withKeyName: "AtTriButeone", withStringValue: "hi")
                    ]
                )

                eventMatcher.matchAndStore(event: customEvent)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())
            }
        }
    }
}
