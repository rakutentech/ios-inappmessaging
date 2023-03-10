import Quick
import Nimble
@testable import RInAppMessaging

/// Tests for campaign validation logic when provided with different custom events
class CustomEventValidationSpec: QuickSpec {
// swiftlint:disable:previous type_body_length

    // swiftlint:disable:next function_body_length
    override func spec() {

        var campaignsValidator: CampaignsValidator!
        var campaignRepository: CampaignRepository!
        var eventMatcher: EventMatcher!
        var validatorHandler: ValidatorHandler!

        func syncRepository(with campaigns: [Campaign]) {
            campaignRepository.syncWith(list: campaigns, timestampMilliseconds: 0, ignoreTooltips: false)
        }

        beforeEach {
            campaignRepository = CampaignRepository(userDataCache: UserDataCacheMock(),
                                                    accountRepository: AccountRepository(userDataCache: UserDataCacheMock()))
            eventMatcher = EventMatcher(campaignRepository: campaignRepository)
            campaignsValidator = CampaignsValidator(
                campaignRepository: campaignRepository,
                eventMatcher: eventMatcher)
            validatorHandler = ValidatorHandler()
        }

        describe("CustomEvent") {
            context("when accessing name") {

                it("should return lowercased string") {
                    let event = CustomEvent(withName: "TeSt4", withCustomAttributes: nil)
                    expect(event.name) == "test4"
                }
            }
        }

        describe("CampaignsValidator") {
            it("should accept a campaign that is matched using an custom event with a STRING type and equals operator") {
                let mockResponse = TestHelpers.MockResponse.stringTypeWithEqualsOperator
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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
                syncRepository(with: mockResponse.data)

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

            it("should accept a campaign that is matched even with a case-insensitive attribute value") {
                let mockResponse = TestHelpers.MockResponse.caseInsensitiveAttributeValue
                syncRepository(with: mockResponse.data)

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
        }
    }
}
