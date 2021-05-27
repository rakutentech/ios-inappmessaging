import Quick
import Nimble
@testable import RInAppMessaging

class ViewPresenterSpec: QuickSpec {

    override func spec() {

        var campaignRepository: CampaignRepositoryMock!
        var impressionService: ImpressionServiceMock!
        var eventMatcher: EventMatcherMock!
        var campaignTriggerAgent: CampaignTriggerAgentMock!

        beforeEach {
            campaignRepository = CampaignRepositoryMock()
            impressionService = ImpressionServiceMock()
            eventMatcher = EventMatcherMock()
            campaignTriggerAgent = CampaignTriggerAgentMock()
        }

        describe("BaseViewPresenter") {

            var presenter: BaseViewPresenter!
            let testCampaign = TestHelpers.generateCampaign(id: "test", test: false,
                                                            delay: 0, maxImpressions: 1)

            beforeEach {
                presenter = BaseViewPresenter(campaignRepository: campaignRepository,
                                             impressionService: impressionService,
                                             eventMatcher: eventMatcher,
                                             campaignTriggerAgent: campaignTriggerAgent)
                presenter.campaign = testCampaign
            }

            context("when logImpression is called") {

                it("will save all logged impressions for sending") {
                    let impressions: [ImpressionType] = [.impression, .actionTwo]
                    impressions.forEach {
                        presenter.logImpression(type: $0)
                    }

                    expect(presenter.impressions.map({ $0.type })).to(elementsEqual(impressions))
                }
            }

            context("when sendImpressions is called") {

                it("will send all logged impressions") {
                    let impressions: [ImpressionType] = [.impression, .actionTwo]
                    impressions.forEach {
                        presenter.logImpression(type: $0)
                    }

                    presenter.sendImpressions()
                    expect(impressionService.sentImpressions?.list).to(equal(impressions))
                }

                it("will send impressions for provided campaign") {
                    let impressions: [ImpressionType] = [.impression, .actionTwo]
                    impressions.forEach {
                        presenter.logImpression(type: $0)
                    }

                    presenter.sendImpressions()
                    expect(impressionService.sentImpressions?.campaignID).to(equal(testCampaign.id))
                }

                it("will clear the list of logged impressions after sending") {
                    let impressions: [ImpressionType] = [.impression, .actionTwo]
                    impressions.forEach {
                        presenter.logImpression(type: $0)
                    }
                    presenter.sendImpressions()
                    expect(presenter.impressions).to(haveCount(0))
                }
            }

            context("when handleButtonTrigger is called") {

                let trigger = Trigger(type: .event, eventType: .custom,
                eventName: "trigger", attributes: [])

                it("will log new event based on the trigger") {
                    presenter.handleButtonTrigger(trigger)
                    let expectedEvent = CommonUtility.convertTriggerObjectToCustomEvent(trigger)
                    expect(eventMatcher.loggedEvents).to(contain(expectedEvent))
                }

                it("will call Trigger Agent") {
                    presenter.handleButtonTrigger(trigger)
                    expect(campaignTriggerAgent.wasValidateAndTriggerCampaignsCalled).to(beTrue())
                }
            }

            context("when optOutCampaign is called") {

                it("will opt out provided campaign") {
                    let campaign = TestHelpers.generateCampaign(id: "test", test: false, delay: 0, maxImpressions: 1)
                    presenter.campaign = campaign
                    presenter.optOutCampaign()
                    expect(presenter.campaign.isOptedOut).to(beTrue())
                    expect(campaignRepository.wasOptOutCalled).to(beTrue())
                }
            }

            context("when showURLError is called") {

                it("will call showAlert on passed view") {
                    let view = FullViewMock()
                    presenter.showURLError(view: view)
                    expect(view.wasShowAlertCalled).to(beTrue())
                }
            }
        }

        describe("SlideUpViewPresenter") {

            var view: SlideUpViewMock!
            var presenter: SlideUpViewPresenter!
            let campaign = TestHelpers.generateCampaign(
                id: "test",
                content: Content(
                    onClickBehavior: OnClickBehavior(action: .close, uri: nil),
                    campaignTrigger: Trigger(type: .event, eventType: .custom,
                                             eventName: "trigger", attributes: [])))

            beforeEach {
                view = SlideUpViewMock()
                presenter = SlideUpViewPresenter(campaignRepository: campaignRepository,
                                                 impressionService: impressionService,
                                                 eventMatcher: eventMatcher,
                                                 campaignTriggerAgent: campaignTriggerAgent)
                presenter.view = view
                presenter.campaign = campaign
            }

            context("when viewDidInitialize is called") {

                it("will call initializeView on the view object") {
                    presenter.viewDidInitialize()
                    expect(view.wasSetupCalled).to(beTrue())
                }
            }

            context("when didClickExitButton is called") {

                it("will call dismiss on the view object") {
                    presenter.didClickExitButton()
                    expect(view.wasDismissCalled).to(beTrue())
                }

                it("will send impressions containing .exit type") {
                    presenter.didClickExitButton()
                    expect(impressionService.sentImpressions?.list).to(contain(.exit))
                }

                it("will not send impressions containing .optOut type") {
                    presenter.didClickExitButton()
                    expect(impressionService.sentImpressions?.list).toNot(contain(.optOut))
                }
            }

            context("when didClickContent is called") {

                it("will call dismiss on the view object") {
                    presenter.didClickContent()
                    expect(view.wasDismissCalled).to(beTrue())
                }

                it("will send impressions containing .clickContent type") {
                    presenter.didClickContent()
                    expect(impressionService.sentImpressions?.list).to(contain(.clickContent))
                }

                it("will not send impressions containing .optOut type") {
                    presenter.didClickContent()
                    expect(impressionService.sentImpressions?.list).toNot(contain(.optOut))
                }

                it("will log new event based on the content's trigger") {
                    presenter.didClickContent()
                    let trigger = campaign.data.messagePayload.messageSettings.controlSettings?.content?.campaignTrigger
                    let expectedEvent = CommonUtility.convertTriggerObjectToCustomEvent(trigger!)
                    expect(eventMatcher.loggedEvents).to(contain(expectedEvent))
                }

                it("will call Trigger Agent if button trigger was present") {
                    presenter.didClickContent()
                    expect(campaignTriggerAgent.wasValidateAndTriggerCampaignsCalled).to(beTrue())
                }

                context("and content URI is present") {

                    it("will show error alert if redirect URL is invalid") {
                        let campaign = TestHelpers.generateCampaign(
                            id: "test",
                            content: Content(
                                onClickBehavior: OnClickBehavior(action: .redirect, uri: ""),
                                campaignTrigger: Trigger(type: .event, eventType: .custom,
                                                         eventName: "trigger", attributes: [])))
                        presenter.campaign = campaign
                        presenter.didClickContent()
                        expect(view.wasShowAlertCalled).to(beTrue())
                    }

                    it("will show error alert if redirect URL couldn't be opened") {
                        let campaign = TestHelpers.generateCampaign(
                            id: "test",
                            content: Content(
                                onClickBehavior: OnClickBehavior(action: .redirect, uri: "unknown_scheme"),
                                campaignTrigger: Trigger(type: .event, eventType: .custom,
                                                         eventName: "trigger", attributes: [])))
                        presenter.campaign = campaign
                        presenter.didClickContent()
                        expect(view.wasShowAlertCalled).toEventually(beTrue())
                    }

                    it("will show error alert if deeplink URL is invalid") {
                        let campaign = TestHelpers.generateCampaign(
                            id: "test",
                            content: Content(
                                onClickBehavior: OnClickBehavior(action: .deeplink, uri: ""),
                                campaignTrigger: Trigger(type: .event, eventType: .custom,
                                                         eventName: "trigger", attributes: [])))
                        presenter.campaign = campaign
                        presenter.didClickContent()
                        expect(view.wasShowAlertCalled).to(beTrue())
                    }

                    it("will show error alert if deeplink URL couldn't be opened") {
                        let campaign = TestHelpers.generateCampaign(
                            id: "test",
                            content: Content(
                                onClickBehavior: OnClickBehavior(action: .deeplink, uri: "unknown_scheme"),
                                campaignTrigger: Trigger(type: .event, eventType: .custom,
                                                         eventName: "trigger", attributes: [])))
                        presenter.campaign = campaign
                        presenter.didClickContent()
                        expect(view.wasShowAlertCalled).toEventually(beTrue())
                    }

                    // testing positive cases for redirect/deepling URL requires UIApplication.shared.openURL() function to be mocked
                }
            }
        }

        describe("FullViewPresenter") {

            var view: FullViewMock!
            var presenter: FullViewPresenter!
            let campaign = TestHelpers.generateCampaign(id: "test", buttons: [
                Button(buttonText: "button1",
                       buttonTextColor: "#000000",
                       buttonBackgroundColor: "#000000",
                       buttonBehavior: ButtonBehavior(action: .close, uri: nil),
                       campaignTrigger: Trigger(type: .event,
                                                eventType: .custom,
                                                eventName: "trigger",
                                                attributes: [])),
                Button(buttonText: "button2",
                       buttonTextColor: "#ffffff",
                       buttonBackgroundColor: "#ffffff",
                       buttonBehavior: ButtonBehavior(action: .redirect, uri: "uri"),
                       campaignTrigger: nil)
            ])
            beforeEach {
                view = FullViewMock()
                presenter = FullViewPresenter(campaignRepository: campaignRepository,
                                              impressionService: impressionService,
                                              eventMatcher: eventMatcher,
                                              campaignTriggerAgent: campaignTriggerAgent)
                presenter.view = view
                presenter.campaign = campaign
            }

            context("when viewDidInitialize is called") {

                it("will call initializeView on the view object") {

                    presenter.viewDidInitialize()
                    expect(view.wasSetupCalled).to(beTrue())
                }
            }

            context("when loadButtons is called") {

                it("will call addButtons on the view object with proper data") {
                    presenter.loadButtons()
                    expect(view.addedButtons.map({ $0.0 })).to(elementsEqual([
                        ActionButton(impression: .actionOne,
                                     uri: nil,
                                     trigger: Trigger(type: .event,
                                                      eventType: .custom,
                                                      eventName: "trigger",
                                                      attributes: [])),
                        ActionButton(impression: .actionTwo,
                                     uri: "uri",
                                     trigger: nil)
                    ]))
                    expect(view.addedButtons.map({ $0.viewModel })).to(elementsEqual([
                        ActionButtonViewModel(text: "button1",
                                              textColor: .blackRGB,
                                              backgroundColor: .blackRGB),
                        ActionButtonViewModel(text: "button2",
                                              textColor: .whiteRGB,
                                              backgroundColor: .whiteRGB)
                    ]))
                }

                it("will call addButtons on the view object with supported buttons only") {
                    let campaign = TestHelpers.generateCampaign(id: "test", buttons: [
                        Button(buttonText: "button1",
                               buttonTextColor: "#ffffff",
                               buttonBackgroundColor: "#ffffff",
                               buttonBehavior: ButtonBehavior(action: .close, uri: nil),
                               campaignTrigger: nil),
                        Button(buttonText: "buttonInvalid",
                               buttonTextColor: "#000000",
                               buttonBackgroundColor: "#000000",
                               buttonBehavior: ButtonBehavior(action: .invalid, uri: nil),
                               campaignTrigger: nil)
                    ])
                    presenter.campaign = campaign
                    presenter.loadButtons()
                    expect(view.addedButtons.map({ $0.viewModel })).to(elementsEqual([
                        ActionButtonViewModel(text: "button1",
                                              textColor: .whiteRGB,
                                              backgroundColor: .whiteRGB)
                    ]))
                }
            }

            context("when didClickAction is called") {

                let sender = ActionButton(impression: .actionOne,
                                          uri: nil,
                                          trigger: Trigger(type: .event,
                                                           eventType: .custom,
                                                           eventName: "trigger",
                                                           attributes: []))

                it("will call dismiss on the view object") {
                    presenter.didClickAction(sender: sender)
                    expect(view.wasDismissCalled).to(beTrue())
                }

                it("will send impressions containing button's impression") {
                    presenter.didClickAction(sender: sender)
                    expect(impressionService.sentImpressions?.list).to(contain(sender.impression))
                }

                it("will send impressions containing .optOut type if campaign was opted out") {
                    view.isOptOutChecked = true
                    presenter.didClickAction(sender: sender)
                    expect(presenter.campaign.isOptedOut).to(beTrue())
                    expect(impressionService.sentImpressions?.list).to(contain(.optOut))
                }

                it("will not send impressions containing .optOut type if campaign was not opted out") {
                    presenter.didClickAction(sender: sender)
                    expect(presenter.campaign.isOptedOut).to(beFalse())
                    expect(impressionService.sentImpressions?.list).toNot(contain(.optOut))
                }

                it("will log new event based on the button's trigger") {
                    presenter.didClickAction(sender: sender)
                    let expectedEvent = CommonUtility.convertTriggerObjectToCustomEvent(sender.trigger!)
                    expect(eventMatcher.loggedEvents).to(contain(expectedEvent))
                }

                it("will call Trigger Agent if button trigger is present") {
                    presenter.didClickAction(sender: sender)
                    expect(campaignTriggerAgent.wasValidateAndTriggerCampaignsCalled).toEventually(beTrue())
                }

                it("will show error alert if redirect URL is invalid") {
                    let sender = ActionButton(impression: .actionOne,
                                              uri: "",
                                              trigger: Trigger(type: .event,
                                                               eventType: .custom,
                                                               eventName: "trigger",
                                                               attributes: []))
                    presenter.didClickAction(sender: sender)
                    expect(view.wasShowAlertCalled).to(beTrue())
                }

                it("will show error alert if redirect URL couldn't be opened") {
                    let sender = ActionButton(impression: .actionOne,
                                              uri: "unknown_scheme",
                                              trigger: Trigger(type: .event,
                                                               eventType: .custom,
                                                               eventName: "trigger",
                                                               attributes: []))
                    presenter.didClickAction(sender: sender)
                    expect(view.wasShowAlertCalled).toEventually(beTrue())
                }

                // testing positive cases for redirect/deepling URL requires UIApplication.shared.openURL() function to be mocked
            }

            context("when didClickExitButton is called") {

                it("will call dismiss on the view object") {
                    presenter.didClickExitButton()
                    expect(view.wasDismissCalled).to(beTrue())
                }

                it("will send impressions containing .exit type") {
                    presenter.didClickExitButton()
                    expect(impressionService.sentImpressions?.list).to(contain(.exit))
                }

                it("will send impressions containing .optOut type if campaign was opted out") {
                    view.isOptOutChecked = true
                    presenter.didClickExitButton()
                    expect(presenter.campaign.isOptedOut).to(beTrue())
                    expect(impressionService.sentImpressions?.list).to(contain(.optOut))
                }

                it("will not send impressions containing .optOut type if campaign was not opted out") {
                    presenter.didClickExitButton()
                    expect(presenter.campaign.isOptedOut).to(beFalse())
                    expect(impressionService.sentImpressions?.list).toNot(contain(.optOut))
                }
            }
        }
    }
}

private class FullViewMock: UIView, FullViewType {

    static var viewIdentifier: String { "FullViewMock" }

    var isOptOutChecked: Bool = false
    var onDismiss: ((_ cancelled: Bool) -> Void)?
    var basePresenter: BaseViewPresenterType = BaseViewPresenterMock()

    private(set) var wasSetupCalled = false
    private(set) var wasDismissCalled = false
    private(set) var wasShowAlertCalled = false
    private(set) var addedButtons = [(ActionButton, viewModel: ActionButtonViewModel)]()

    func setup(viewModel: FullViewModel) {
        wasSetupCalled = true
    }

    func dismiss() {
        wasDismissCalled = true
    }

    func addButtons(_ buttons: [(ActionButton, viewModel: ActionButtonViewModel)]) {
        addedButtons = buttons
    }

    func showAlert(title: String, message: String, style: UIAlertController.Style, actions: [UIAlertAction]) {
        wasShowAlertCalled = true
    }

    func animateOnShow(completion: @escaping () -> Void) { completion() }
    func constraintsForParent(_ parent: UIView) -> [NSLayoutConstraint] { [] }
}

private class SlideUpViewMock: UIView, SlideUpViewType {

    static var viewIdentifier: String { "SlideUpViewMock" }

    var onDismiss: ((_ cancelled: Bool) -> Void)?
    var basePresenter: BaseViewPresenterType = BaseViewPresenterMock()

    private(set) var wasSetupCalled = false
    private(set) var wasDismissCalled = false
    private(set) var wasShowAlertCalled = false

    func setup(viewModel: SlideUpViewModel) {
        wasSetupCalled = true
    }

    func dismiss() {
        wasDismissCalled = true
    }

    func showAlert(title: String, message: String, style: UIAlertController.Style, actions: [UIAlertAction]) {
        wasShowAlertCalled = true
    }

    func animateOnShow(completion: @escaping () -> Void) { completion() }
    func constraintsForParent(_ parent: UIView) -> [NSLayoutConstraint] { [] }
}
