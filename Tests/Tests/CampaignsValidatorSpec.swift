import Quick
import Nimble
@testable import RInAppMessaging

class CampaignsValidatorSpec: QuickSpec {

    override func spec() {

        var campaignsValidator: CampaignsValidator!
        var campaignRepository: CampaignRepository!
        var eventMatcher: EventMatcher!
        var validatorHandler: ValidatorHandler!

        beforeEach {
            campaignRepository = CampaignRepository(userDataCache: UserDataCacheMock(),
                                                    accountRepository: AccountRepository(userDataCache: UserDataCacheMock()))
            eventMatcher = EventMatcher(campaignRepository: campaignRepository)
            campaignsValidator = CampaignsValidator(
                campaignRepository: campaignRepository,
                eventMatcher: eventMatcher)
            validatorHandler = ValidatorHandler()
        }

        describe("CampaignsValidator") {
            it("will accept test campaign (not looking at triggers)") {
                campaignRepository.syncWith(list: [MockedCampaigns.testCampaign], timestampMilliseconds: 0)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedCampaigns).to(elementsEqual([MockedCampaigns.testCampaign]))
            }

            it("will accept outdated test campaign") {
                campaignRepository.syncWith(list: [MockedCampaigns.outdatedTestCampaign], timestampMilliseconds: 0)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedCampaigns).to(contain(MockedCampaigns.outdatedTestCampaign))
            }

            it("will not accept test campaign with impressionLeft < 1") {
                let testCampaign = TestHelpers.generateCampaign(id: "test", maxImpressions: 1, test: true)
                campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())
            }

            it("will accept every non-test campaign matching criteria") {
                let campaign = TestHelpers.generateCampaign(
                    id: "test", maxImpressions: 2,
                    triggers: [Trigger(
                        type: .event,
                        eventType: .loginSuccessful,
                        eventName: "testevent",
                        attributes: []
                        )])
                campaignRepository.syncWith(list: [campaign, MockedCampaigns.outdatedCampaign],
                                            timestampMilliseconds: 0)
                let event = LoginSuccessfulEvent()
                eventMatcher.matchAndStore(event: event)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(elementsEqual(
                    [ValidatorHandler.Element(campaign, [event])]))
            }

            it("won't accept campaigns with no impressions left") {
                let campaign = TestHelpers.generateCampaign(
                    id: "test", maxImpressions: 0,
                    triggers: [Trigger(
                        type: .event,
                        eventType: .loginSuccessful,
                        eventName: "testevent",
                        attributes: []
                        )])
                campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedCampaigns).toEventuallyNot(contain(campaign))
            }

            it("won't accept outdated campaigns") {
                campaignRepository.syncWith(list: [MockedCampaigns.outdatedCampaign], timestampMilliseconds: 0)
                eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedCampaigns).toNot(contain(MockedCampaigns.outdatedCampaign))
            }

            it("won't accept opted out campaigns") {
                let campaign = TestHelpers.generateCampaign(
                    id: "test", maxImpressions: 2,
                    triggers: [Trigger(
                        type: .event,
                        eventType: .loginSuccessful,
                        eventName: "testevent",
                        attributes: []
                        )])
                campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                _ = campaignRepository.optOutCampaign(campaign)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedCampaigns).toEventuallyNot(contain(campaign))
            }

            context("when evaluating triggers") {

                it("will accept campaign when triggers are satifsied") {
                    let campaign = TestHelpers.generateCampaign(
                        id: "test", maxImpressions: 2,
                        triggers: [
                            Trigger(
                                type: .event,
                                eventType: .loginSuccessful,
                                eventName: "testevent",
                                attributes: []),
                            Trigger(
                                type: .event,
                                eventType: .appStart,
                                eventName: "testevent2",
                                attributes: []
                            )])
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    eventMatcher.matchAndStore(event: AppStartEvent())
                    campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                    expect(validatorHandler.validatedCampaigns).to(contain(campaign))
                }

                it("won't accept campaign with no triggers") {
                    let campaign = TestHelpers.generateCampaign(
                        id: "test", maxImpressions: 2,
                        triggers: [])
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                    expect(validatorHandler.validatedCampaigns).toEventuallyNot(contain(campaign))
                }

                it("won't accept campaign when not all triggers are satisfied") {
                    let campaign = TestHelpers.generateCampaign(
                        id: "test", maxImpressions: 2,
                        triggers: [
                            Trigger(
                                type: .event,
                                eventType: .loginSuccessful,
                                eventName: "testevent",
                                attributes: []),
                            Trigger(
                                type: .event,
                                eventType: .appStart,
                                eventName: "testevent2",
                                attributes: []
                            )])
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                    expect(validatorHandler.validatedCampaigns).toEventuallyNot(contain(campaign))
                }
            }
        }
    }
}

private enum MockedCampaigns {
    static let testCampaign = Campaign(
        data: CampaignData(
            campaignId: "test",
            maxImpressions: 1,
            type: .modal,
            triggers: [],
            isTest: true,
            infiniteImpressions: false,
            hasNoEndDate: false,
            isCampaignDismissable: true,
            messagePayload: MessagePayload(
                title: "testTitle",
                messageBody: "testBody",
                header: "testHeader",
                titleColor: "#000000",
                headerColor: "#444444",
                messageBodyColor: "#FAFAFA",
                backgroundColor: "#FAFAFA",
                frameColor: "#FF2222",
                resource: Resource(
                    imageUrl: nil,
                    cropType: .fill),
                messageSettings: MessageSettings(
                    displaySettings: DisplaySettings(
                        orientation: .portrait,
                        slideFrom: .bottom,
                        endTimeMilliseconds: Int64.max,
                        textAlign: .fill,
                        optOut: false,
                        html: false,
                        delay: 0),
                    controlSettings: ControlSettings(buttons: [], content: nil))
            )
        ))

    static let outdatedTestCampaign = Campaign(
        data: CampaignData(
            campaignId: "test",
            maxImpressions: 1,
            type: .modal,
            triggers: [],
            isTest: true,
            infiniteImpressions: false,
            hasNoEndDate: false,
            isCampaignDismissable: true,
            messagePayload: MessagePayload(
                title: "testTitle",
                messageBody: "testBody",
                header: "testHeader",
                titleColor: "#000000",
                headerColor: "#444444",
                messageBodyColor: "#FAFAFA",
                backgroundColor: "#FAFAFA",
                frameColor: "#FF2222",
                resource: Resource(
                    imageUrl: nil,
                    cropType: .fill),
                messageSettings: MessageSettings(
                    displaySettings: DisplaySettings(
                        orientation: .portrait,
                        slideFrom: .bottom,
                        endTimeMilliseconds: 0,
                        textAlign: .fill,
                        optOut: false,
                        html: false,
                        delay: 0),
                    controlSettings: ControlSettings(buttons: [], content: nil))
            )
        ))

    static let outdatedCampaign = Campaign(
        data: CampaignData(
            campaignId: "test",
            maxImpressions: 2,
            type: .modal,
            triggers: [
                Trigger(
                    type: .event,
                    eventType: .loginSuccessful,
                    eventName: "testevent",
                    attributes: []
                )
            ],
            isTest: false,
            infiniteImpressions: false,
            hasNoEndDate: false,
            isCampaignDismissable: true,
            messagePayload: MessagePayload(
                title: "testTitle",
                messageBody: "testBody",
                header: "testHeader",
                titleColor: "#000000",
                headerColor: "#444444",
                messageBodyColor: "#FAFAFA",
                backgroundColor: "#FAFAFA",
                frameColor: "#FF2222",
                resource: Resource(
                    imageUrl: nil,
                    cropType: .fill),
                messageSettings: MessageSettings(
                    displaySettings: DisplaySettings(
                        orientation: .portrait,
                        slideFrom: .bottom,
                        endTimeMilliseconds: 0,
                        textAlign: .fill,
                        optOut: false,
                        html: false,
                        delay: 0),
                    controlSettings: ControlSettings(buttons: [], content: nil))
            )
        ))
}
