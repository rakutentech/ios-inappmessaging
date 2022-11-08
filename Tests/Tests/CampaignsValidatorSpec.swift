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

            it("will accept outdated test campaign") {
                campaignRepository.syncWith(list: [MockedCampaigns.outdatedTestCampaign], timestampMilliseconds: 0)
                eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedCampaigns).to(contain(MockedCampaigns.outdatedTestCampaign))
            }

            it("will not accept test campaign with impressionLeft < 1") {
                let testCampaign = TestHelpers.generateCampaign(id: "test", maxImpressions: 1, test: true)
                campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                campaignRepository.decrementImpressionsLeftInCampaign(id: testCampaign.id)
                eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(beEmpty())
            }

            it("will accept non-test campaigns with matching criteria") {
                let campaign = TestHelpers.generateCampaign(
                    id: "test", maxImpressions: 2,
                    triggers: [Trigger.loginEventTrigger])
                campaignRepository.syncWith(list: [campaign, MockedCampaigns.outdatedCampaign],
                                            timestampMilliseconds: 0)
                let event = LoginSuccessfulEvent()
                eventMatcher.matchAndStore(event: event)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(elementsEqual(
                    [ValidatorHandler.Element(campaign, [event])]))
            }

            it("will accept test campaigns with matching criteria") {
                campaignRepository.syncWith(list: [MockedCampaigns.testCampaign, MockedCampaigns.outdatedCampaign],
                                            timestampMilliseconds: 0)
                let event = LoginSuccessfulEvent()
                eventMatcher.matchAndStore(event: event)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(elementsEqual(
                    [ValidatorHandler.Element(MockedCampaigns.testCampaign, [event])]))
            }

            it("won't accept campaigns with no impressions left") {
                let campaign = TestHelpers.generateCampaign(
                    id: "test", maxImpressions: 0,
                    triggers: [Trigger.loginEventTrigger])
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
                    triggers: [Trigger.loginEventTrigger])
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

                it("will accept test campaign when triggers are satifsied") {
                    let campaign = TestHelpers.generateCampaign(
                        id: "test", maxImpressions: 2, test: true,
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
                    expect(validatorHandler.validatedCampaigns).to(beEmpty())
                }

                it("will not accept test campaign without triggers") {
                    let campaign = TestHelpers.generateCampaign(
                        id: "test", maxImpressions: 2, test: true,
                        triggers: [])
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                    expect(validatorHandler.validatedCampaigns).to(beEmpty())
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
    private static let outdatedMessagePayload = MessagePayload(
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

    static let testCampaign = TestHelpers.generateCampaign(
        id: "test", maxImpressions: 2, test: true,
        triggers: [Trigger.loginEventTrigger])

    static let outdatedTestCampaign = Campaign(
        data: CampaignData(
            campaignId: "test",
            maxImpressions: 1,
            type: .modal,
            triggers: [Trigger.loginEventTrigger],
            isTest: true,
            infiniteImpressions: false,
            hasNoEndDate: false,
            isCampaignDismissable: true,
            messagePayload: outdatedMessagePayload
        )
    )

    static let outdatedCampaign = Campaign(
        data: CampaignData(
            campaignId: "test",
            maxImpressions: 2,
            type: .modal,
            triggers: [Trigger.loginEventTrigger],
            isTest: false,
            infiniteImpressions: false,
            hasNoEndDate: false,
            isCampaignDismissable: true,
            messagePayload: outdatedMessagePayload
        )
    )
}
