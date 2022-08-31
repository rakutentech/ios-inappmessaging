import UIKit
import Quick
import Nimble
@testable import RInAppMessaging

// swiftlint:disable:next type_body_length
class ViewPresenterSpec: QuickSpec {

    // swiftlint:disable:next function_body_length
    override func spec() {

        var campaignRepository: CampaignRepositoryMock!
        var impressionService: ImpressionServiceMock!
        var eventMatcher: EventMatcherMock!
        var campaignTriggerAgent: CampaignTriggerAgentMock!
        let bundleInfo = BundleInfoMock.self

        beforeEach {
            campaignRepository = CampaignRepositoryMock()
            impressionService = ImpressionServiceMock()
            eventMatcher = EventMatcherMock()
            campaignTriggerAgent = CampaignTriggerAgentMock()
            bundleInfo.reset()
        }

        describe("BaseViewPresenter") {

            var presenter: BaseViewPresenter!
            let testCampaign = TestHelpers.generateCampaign(id: "test", maxImpressions: 1)

            beforeEach {
                presenter = BaseViewPresenter(campaignRepository: campaignRepository,
                                              impressionService: impressionService,
                                              eventMatcher: eventMatcher,
                                              campaignTriggerAgent: campaignTriggerAgent)
                presenter.campaign = testCampaign
                presenter.bundleInfo = bundleInfo
            }

            context("when logImpression is called") {

                it("will save all logged impressions for sending") {
                    let impressions: [ImpressionType] = [.impression, .actionTwo]
                    impressions.forEach {
                        presenter.logImpression(type: $0)
                    }

                    expect(presenter.impressions.map({ $0.type })).to(elementsEqual(impressions))
                }

                it("will send `impression` type to RAnalytics with all required properties") {
                    bundleInfo.inAppSubscriptionIdMock = "sub-id"

                    expect {
                        presenter.logImpression(type: .impression)
                    }.toEventually(postNotifications(containElementSatisfying({
                        let params = $0.object as? [String: Any]
                        let data = params?["eventData"] as? [String: Any]
                        let impressions = data?[Constants.RAnalytics.Keys.impressions] as? [[String: Any]]

                        return data != nil &&
                        impressions?.count == 1 &&
                        impressions?.first?[Constants.RAnalytics.Keys.action] as? Int == ImpressionType.impression.rawValue &&
                        data?[Constants.RAnalytics.Keys.subscriptionID] as? String == bundleInfo.inAppSubscriptionIdMock &&
                        data?[Constants.RAnalytics.Keys.campaignID] as? String == testCampaign.id
                    })))
                }

                it("will not send impression types other than `impression` to RAnalytics") {
                    var receivedNotification: Notification?
                    let observer = NotificationCenter.default.addObserver(forName: .rAnalyticsCustomEvent,
                                                                          object: nil,
                                                                          queue: OperationQueue()) { notification in
                        receivedNotification = notification
                    }

                    let impressions: [ImpressionType] = [.actionOne, .actionTwo, .exit, .clickContent, .invalid, .optOut]
                    impressions.forEach {
                        presenter.logImpression(type: $0)
                    }

                    expect(receivedNotification).toAfterTimeout(beNil())
                    NotificationCenter.default.removeObserver(observer)
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
                    let campaign = TestHelpers.generateCampaign(id: "test")
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

                it("will call initializeView on the view object with expected model") {
                    presenter.viewDidInitialize()
                    expect(view.viewModel).toNot(beNil())
                    expect(view.viewModel?.isDismissable).to(equal(campaign.data.isCampaignDismissable))
                    expect(view.viewModel?.backgroundColor).to(equal(UIColor(hexString: campaign.data.messagePayload.backgroundColor)!))
                    expect(view.viewModel?.messageBody).to(equal(campaign.data.messagePayload.messageBody))
                    expect(view.viewModel?.messageBodyColor).to(equal(UIColor(hexString: campaign.data.messagePayload.messageBodyColor)!))
                    expect(view.viewModel?.slideFromDirection).to(equal(campaign.data.messagePayload.messageSettings.displaySettings.slideFrom))
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
                    let trigger = campaign.data.messagePayload.messageSettings.controlSettings.content?.campaignTrigger
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

                    // testing positive cases for redirect/deeplink URL requires UIApplication.shared.openURL() function to be mocked
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
            let pushPrimerOptions: UNAuthorizationOptions = [.badge, .sound, .criticalAlert]
            var notificationCenterMock: UNUserNotificationCenterMock!
            var errorDelegate: ErrorDelegateMock!

            beforeEach {
                view = FullViewMock()
                notificationCenterMock = UNUserNotificationCenterMock()
                errorDelegate = ErrorDelegateMock()
                presenter = FullViewPresenter(campaignRepository: campaignRepository,
                                              impressionService: impressionService,
                                              eventMatcher: eventMatcher,
                                              campaignTriggerAgent: campaignTriggerAgent,
                                              pushPrimerOptions: pushPrimerOptions,
                                              notificationCenter: notificationCenterMock)
                presenter.view = view
                presenter.campaign = campaign
                presenter.errorDelegate = errorDelegate
            }

            context("when viewDidInitialize is called") {

                it("will call initializeView on the view object") {
                    presenter.viewDidInitialize()
                    expect(view.wasSetupCalled).to(beTrue())
                }

                if #available(iOS 13.0, *) {
                    it("will call initializeView on the view object with expected model") {
                        presenter.associatedImage = UIImage(named: "test-image", in: .unitTests, with: nil)
                        presenter.viewDidInitialize()

                        expect(view.viewModel).toNot(beNil())
                        expect(view.viewModel?.isDismissable).to(equal(campaign.data.isCampaignDismissable))
                        expect(view.viewModel?.backgroundColor).to(equal(UIColor(hexString: campaign.data.messagePayload.backgroundColor)!))
                        expect(view.viewModel?.messageBody).to(equal(campaign.data.messagePayload.messageBody))
                        expect(view.viewModel?.messageBodyColor).to(equal(UIColor(hexString: campaign.data.messagePayload.messageBodyColor)!))
                        expect(view.viewModel?.image).to(equal(presenter.associatedImage))
                        expect(view.viewModel?.title).to(equal(campaign.data.messagePayload.title))
                        expect(view.viewModel?.titleColor).to(equal(UIColor(hexString: campaign.data.messagePayload.titleColor)!))
                        expect(view.viewModel?.header).to(equal(campaign.data.messagePayload.header))
                        expect(view.viewModel?.headerColor).to(equal(UIColor(hexString: campaign.data.messagePayload.headerColor)!))
                        expect(view.viewModel?.showOptOut).to(equal(campaign.data.messagePayload.messageSettings.displaySettings.optOut))
                        expect(view.viewModel?.showButtons).to(equal(!campaign.data.messagePayload.messageSettings.controlSettings.buttons.isEmpty))
                        expect(view.viewModel?.isHTML).to(beFalse())
                    }
                }
            }

            context("when loadButtons is called") {

                it("will call addButtons on the view object with proper data") {
                    presenter.loadButtons()
                    expect(view.addedButtons.map({ $0.0 })).to(elementsEqual([
                        ActionButton(type: .close,
                                     impression: .actionOne,
                                     uri: nil,
                                     trigger: Trigger(type: .event,
                                                      eventType: .custom,
                                                      eventName: "trigger",
                                                      attributes: [])),
                        ActionButton(type: .redirect,
                                     impression: .actionTwo,
                                     uri: "uri",
                                     trigger: nil)
                    ]))
                    expect(view.addedButtons.map({ $0.viewModel })).to(elementsEqual([
                        ActionButtonViewModel(text: "button1",
                                              textColor: .blackRGB,
                                              backgroundColor: .blackRGB,
                                              shouldDrawBorder: false),
                        ActionButtonViewModel(text: "button2",
                                              textColor: .whiteRGB,
                                              backgroundColor: .whiteRGB,
                                              shouldDrawBorder: true)
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
                                              backgroundColor: .whiteRGB,
                                              shouldDrawBorder: true)
                    ]))
                }
            }

            context("when didClickAction is called") {

                let sender = ActionButton(type: .close,
                                          impression: .actionOne,
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
                    let sender = ActionButton(type: .close,
                                              impression: .actionOne,
                                              uri: "",
                                              trigger: Trigger(type: .event,
                                                               eventType: .custom,
                                                               eventName: "trigger",
                                                               attributes: []))
                    presenter.didClickAction(sender: sender)
                    expect(view.wasShowAlertCalled).to(beTrue())
                }

                it("will show error alert if redirect URL couldn't be opened") {
                    let sender = ActionButton(type: .close,
                                              impression: .actionOne,
                                              uri: "unknown_scheme",
                                              trigger: Trigger(type: .event,
                                                               eventType: .custom,
                                                               eventName: "trigger",
                                                               attributes: []))
                    presenter.didClickAction(sender: sender)
                    expect(view.wasShowAlertCalled).toEventually(beTrue())
                }

                // testing positive cases for redirect/deeplink URL requires UIApplication.shared.openURL() function to be mocked

                context("and action type is .pushPrimer") {
                    let sender = ActionButton(type: .pushPrimer,
                                              impression: .actionOne,
                                              uri: nil, trigger: nil)

                    it("will call dismiss on the view object") {
                        presenter.didClickAction(sender: sender)
                        expect(view.wasDismissCalled).to(beTrue())
                    }

                    it("will send impressions containing button's impression") {
                        presenter.didClickAction(sender: sender)
                        expect(impressionService.sentImpressions?.list).to(contain(sender.impression))
                    }

                    it("will request notification authorization") {
                        presenter.didClickAction(sender: sender)
                        expect(notificationCenterMock.requestAuthorizationCallState.didCall).to(beTrue())
                    }

                    it("will request notification authorization with provided options") {
                        presenter.didClickAction(sender: sender)
                        expect(notificationCenterMock.requestAuthorizationCallState.options).to(equal(pushPrimerOptions))
                    }

                    context("when authorization is granted") {
                        it("will register for remote notifications") {
                            presenter.didClickAction(sender: sender)
                            expect(notificationCenterMock.didCallRegisterForRemoteNotifications).toEventually(beTrue())
                        }
                    }

                    context("when authorization is not granted") {
                        beforeEach {
                            notificationCenterMock.authorizationGranted = false
                        }

                        it("will not try to register for remote notifications") {
                            presenter.didClickAction(sender: sender)
                            expect(notificationCenterMock.didCallRegisterForRemoteNotifications).toAfterTimeout(beFalse())
                        }

                        it("will report an error with expected message") {
                            presenter.didClickAction(sender: sender)
                            expect(errorDelegate.wasErrorReceived).to(beTrue())
                            expect(errorDelegate.receivedError?.localizedDescription)
                                .to(contain("PushPrimer: User has not granted authorization"))
                        }
                    }

                    context("when authorization returned an error") {
                        let authorizationError = NSError(domain: "sample error", code: 100)

                        beforeEach {
                            notificationCenterMock.authorizationRequestError = authorizationError
                        }

                        it("will not try to register for remote notifications") {
                            presenter.didClickAction(sender: sender)
                            expect(notificationCenterMock.didCallRegisterForRemoteNotifications).toAfterTimeout(beFalse())
                        }

                        it("will report an error with associated error object") {
                            presenter.didClickAction(sender: sender)
                            expect(errorDelegate.wasErrorReceived).to(beTrue())
                            expect(errorDelegate.receivedError?.localizedDescription)
                                .to(contain("PushPrimer: UNUserNotificationCenter requestAuthorization failed"))
                            expect(errorDelegate.receivedError?.userInfo["data"] as? NSError)
                                .to(equal(authorizationError))
                        }
                    }
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
    private(set) var viewModel: FullViewModel?

    func setup(viewModel: FullViewModel) {
        wasSetupCalled = true
        self.viewModel = viewModel
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
    private(set) var viewModel: SlideUpViewModel?

    func setup(viewModel: SlideUpViewModel) {
        wasSetupCalled = true
        self.viewModel = viewModel
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
