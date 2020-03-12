import Quick
import Nimble
@testable import RInAppMessaging

class BaseViewPresenterTests: QuickSpec {

    override func spec() {

        var campaignsValidator: CampaignsValidatorMock!
        var campaignRepository: CampaignRepositoryMock!
        var impressionClient: ImpressionClientMock!
        var eventMatcher: EventMatcherMock!
        var readyCampaignDispatcher: ReadyCampaignDispatcherStub!

        beforeEach {
            campaignsValidator = CampaignsValidatorMock()
            campaignRepository = CampaignRepositoryMock()
            impressionClient = ImpressionClientMock()
            eventMatcher = EventMatcherMock()
            readyCampaignDispatcher = ReadyCampaignDispatcherStub()
        }
        describe("BaseViewPresenter") {

            var presenter: BaseViewPresenter!
            let defaultCampaign = TestHelpers.generateCampaign(id: "test", test: false, delay: 0, maxImpressions: 1)

            beforeEach {
                presenter = BaseViewPresenter(campaignsValidator: campaignsValidator,
                                             campaignRepository: campaignRepository,
                                             impressionClient: impressionClient,
                                             eventMatcher: eventMatcher,
                                             readyCampaignDispatcher: readyCampaignDispatcher)
                presenter.campaign = defaultCampaign
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
                    expect(impressionClient.sentImpressions?.list).to(equal(impressions))
                }

                it("will send impressions for provided campaign") {
                    let impressions: [ImpressionType] = [.impression, .actionTwo]
                    impressions.forEach {
                        presenter.logImpression(type: $0)
                    }

                    presenter.sendImpressions()
                    expect(impressionClient.sentImpressions?.campaignID).to(equal(defaultCampaign.id))
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

                it("will re-validate campaigns list") {
                    presenter.handleButtonTrigger(trigger)
                    expect(campaignsValidator.wasValidateCalled).to(beTrue())
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
                presenter = SlideUpViewPresenter(campaignsValidator: campaignsValidator,
                                                 campaignRepository: campaignRepository,
                                                 impressionClient: impressionClient,
                                                 eventMatcher: eventMatcher,
                                                 readyCampaignDispatcher: readyCampaignDispatcher)
                presenter.view = view
                presenter.campaign = campaign
            }

            context("when viewDidInitialize is called") {

                it("will call initializeView on the view object") {
                    presenter.viewDidInitialize()
                    expect(view.wasInitializeViewCalled).to(beTrue())
                }
            }

            context("when didClickExitButton is called") {

                it("will call dismiss on the view object") {
                    presenter.didClickExitButton()
                    expect(view.wasDismissCalled).to(beTrue())
                }

                it("will send impressions containing .exit type") {
                    presenter.didClickExitButton()
                    expect(impressionClient.sentImpressions?.list).to(contain(.exit))
                }

                it("will not send impressions containing .optOut type") {
                    presenter.didClickExitButton()
                    expect(impressionClient.sentImpressions?.list).toNot(contain(.optOut))
                }
            }

            context("when didClickContent is called") {

                it("will call dismiss on the view object") {
                    presenter.didClickContent()
                    expect(view.wasDismissCalled).to(beTrue())
                }

                it("will send impressions containing .clickContent type") {
                    presenter.didClickContent()
                    expect(impressionClient.sentImpressions?.list).to(contain(.clickContent))
                }

                it("will not send impressions containing .optOut type") {
                    presenter.didClickContent()
                    expect(impressionClient.sentImpressions?.list).toNot(contain(.optOut))
                }

                it("will log new event based on the content's trigger") {
                    presenter.didClickContent()
                    let trigger = campaign.data.messagePayload.messageSettings.controlSettings?.content?.campaignTrigger
                    let expectedEvent = CommonUtility.convertTriggerObjectToCustomEvent(trigger!)
                    expect(eventMatcher.loggedEvents).to(contain(expectedEvent))
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
                presenter = FullViewPresenter(campaignsValidator: campaignsValidator,
                                                 campaignRepository: campaignRepository,
                                                 impressionClient: impressionClient,
                                                 eventMatcher: eventMatcher,
                                                 readyCampaignDispatcher: readyCampaignDispatcher)
                presenter.view = view
                presenter.campaign = campaign
            }

            context("when viewDidInitialize is called") {

                it("will call initializeView on the view object") {

                    presenter.viewDidInitialize()
                    expect(view.wasInitializeViewCalled).to(beTrue())
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
                    expect(impressionClient.sentImpressions?.list).to(contain(sender.impression))
                }

                it("will send impressions containing .optOut type if campaign was opted out") {
                    view.isOptOutChecked = true
                    presenter.didClickAction(sender: sender)
                    expect(presenter.campaign.isOptedOut).to(beTrue())
                    expect(impressionClient.sentImpressions?.list).to(contain(.optOut))
                }

                it("will not send impressions containing .optOut type if campaign was not opted out") {
                    presenter.didClickAction(sender: sender)
                    expect(presenter.campaign.isOptedOut).to(beFalse())
                    expect(impressionClient.sentImpressions?.list).toNot(contain(.optOut))
                }

                it("will log new event based on the button's trigger") {
                    presenter.didClickAction(sender: sender)
                    let expectedEvent = CommonUtility.convertTriggerObjectToCustomEvent(sender.trigger!)
                    expect(eventMatcher.loggedEvents).to(contain(expectedEvent))
                }
            }

            context("when didClickExitButton is called") {

                it("will call dismiss on the view object") {
                    presenter.didClickExitButton()
                    expect(view.wasDismissCalled).to(beTrue())
                }

                it("will send impressions containing .exit type") {
                    presenter.didClickExitButton()
                    expect(impressionClient.sentImpressions?.list).to(contain(.exit))
                }

                it("will send impressions containing .optOut type if campaign was opted out") {
                    view.isOptOutChecked = true
                    presenter.didClickExitButton()
                    expect(presenter.campaign.isOptedOut).to(beTrue())
                    expect(impressionClient.sentImpressions?.list).to(contain(.optOut))
                }

                it("will not send impressions containing .optOut type if campaign was not opted out") {
                    presenter.didClickExitButton()
                    expect(presenter.campaign.isOptedOut).to(beFalse())
                    expect(impressionClient.sentImpressions?.list).toNot(contain(.optOut))
                }
            }
        }
    }
}

private class FullViewMock: UIView, FullViewType {
    var isOptOutChecked: Bool = false
    var onDismiss: (() -> Void)?

    private(set) var wasInitializeViewCalled = false
    private(set) var wasDismissCalled = false
    private(set) var addedButtons = [(ActionButton, viewModel: ActionButtonViewModel)]()

    func initializeView(viewModel: FullViewModel) {
        wasInitializeViewCalled = true
    }

    func dismiss() {
        wasDismissCalled = true
    }

    func addButtons(_ buttons: [(ActionButton, viewModel: ActionButtonViewModel)]) {
        addedButtons = buttons
    }
}

private class SlideUpViewMock: UIView, SlideUpViewType {
    var onDismiss: (() -> Void)?

    private(set) var wasInitializeViewCalled = false
    private(set) var wasDismissCalled = false

    func initializeView(viewModel: SlideUpViewModel) {
        wasInitializeViewCalled = true
    }

    func dismiss() {
        wasDismissCalled = true
    }
}

private class CampaignsValidatorMock: CampaignsValidatorType {
    private(set) var wasValidateCalled = false
    func validate(validatedCampaignHandler: (Campaign, Set<Event>) -> Void) {
        wasValidateCalled = true
    }
}

private class CampaignRepositoryMock: CampaignRepositoryType {
    var resourcesToLock: [LockableResource] = []
    var list: [Campaign] = []
    var lastSyncInMilliseconds: Int64?

    private(set) var wasOptOutCalled = false

    func optOutCampaign(_ campaign: Campaign) -> Campaign? {
        wasOptOutCalled = true
        return Campaign.updatedCampaign(campaign, asOptedOut: true)
    }

    func syncWith(list: [Campaign], timestampMilliseconds: Int64) { }
    func decrementImpressionsLeftInCampaign(_ campaign: Campaign) -> Campaign? { return nil }
}

private class ImpressionClientMock: ImpressionClientType {
    weak var errorDelegate: ErrorDelegate?
    var sentImpressions: (list: [ImpressionType], campaignID: String)?

    func pingImpression(impressions: [Impression], campaignData: CampaignData) {
        sentImpressions = (impressions.map({ $0.type }), campaignData.campaignId)
    }
}

private class EventMatcherMock: EventMatcherType {
    private(set) var loggedEvents = [Event]()
    func matchAndStore(event: Event) {
        loggedEvents.append(event)
    }

    func matchedEvents(for campaign: Campaign) -> [Event] { return [] }
    func containsAllMatchedEvents(for campaign: Campaign) -> Bool { return true }
    func removeSetOfMatchedEvents(_ eventsToRemove: Set<Event>, for campaign: Campaign) throws { }
}

private class ReadyCampaignDispatcherStub: ReadyCampaignDispatcherType {
    func addToQueue(campaign: Campaign) { }
    func dispatchAllIfNeeded() { }
}

private extension UIColor {
    static var blackRGB: UIColor {
        return UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
    static var whiteRGB: UIColor {
        return UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    }
}
