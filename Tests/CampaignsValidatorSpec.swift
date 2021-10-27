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
            it("will accept every test campaign (not looking at triggers)") {
                campaignRepository.syncWith(list: [MockedCampaigns.testCampaign], timestampMilliseconds: 0)
                campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                expect(validatorHandler.validatedElements).to(elementsEqual(
                    [ValidatorHandler.Element(MockedCampaigns.testCampaign, [])]))
            }

            it("will accept every non-test campaign matching criteria") {
                let campaign = TestHelpers.generateCampaign(
                    id: "test", test: false, delay: 0, maxImpressions: 2,
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
                    id: "test", test: false, delay: 0, maxImpressions: 0,
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
                expect(validatorHandler.validatedCampaigns).toEventuallyNot(contain(MockedCampaigns.outdatedCampaign))
            }

            it("won't accept opted out campaigns") {
                let campaign = TestHelpers.generateCampaign(
                    id: "test", test: false, delay: 0, maxImpressions: 2,
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
                        id: "test", test: false, delay: 0, maxImpressions: 2,
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
                        id: "test", test: false, delay: 0, maxImpressions: 2,
                        triggers: [])
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    eventMatcher.matchAndStore(event: LoginSuccessfulEvent())
                    campaignsValidator.validate(validatedCampaignHandler: validatorHandler.closure)
                    expect(validatorHandler.validatedCampaigns).toEventuallyNot(contain(campaign))
                }

                it("won't accept campaign when not all triggers are satisfied") {
                    let campaign = TestHelpers.generateCampaign(
                        id: "test", test: false, delay: 0, maxImpressions: 2,
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
    static let testCampaign: Campaign = {
        return Campaign(
            data: CampaignData(
                campaignId: "test",
                maxImpressions: 0,
                type: .modal,
                triggers: [],
                isTest: true,
                messagePayload: MessagePayload(
                    title: "testTitle",
                    messageBody: "testBody",
                    header: "testHeader",
                    titleColor: "color",
                    headerColor: "color2",
                    messageBodyColor: "color3",
                    backgroundColor: "color4",
                    frameColor: "color5",
                    resource: Resource(
                        imageUrl: "",
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
    }()

    static let outdatedCampaign: Campaign = {
        return Campaign(
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
                messagePayload: MessagePayload(
                    title: "testTitle",
                    messageBody: "testBody",
                    header: "testHeader",
                    titleColor: "color",
                    headerColor: "color2",
                    messageBodyColor: "color3",
                    backgroundColor: "color4",
                    frameColor: "color5",
                    resource: Resource(
                        imageUrl: "",
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
    }()
}
