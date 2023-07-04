import UIKit
import UserNotifications

internal protocol FullViewPresenterType: BaseViewPresenterType {
    var view: FullViewType? { get set }

    func loadButtons()
    func didClickAction(sender: ActionButton)
    func didClickExitButton()
}

internal class FullViewPresenter: BaseViewPresenter, FullViewPresenterType, ErrorReportable {
    weak var view: FullViewType?
    var errorDelegate: ErrorDelegate?

    private let pushPrimerOptions: UNAuthorizationOptions
    private let notificationCenter: RemoteNotificationRequestable
    private var viewBackgroundColor: UIColor {
        UIColor(hexString: campaign.data.messagePayload.backgroundColor) ?? .white
    }

    init(campaignRepository: CampaignRepositoryType,
         impressionService: ImpressionServiceType,
         eventMatcher: EventMatcherType,
         campaignTriggerAgent: CampaignTriggerAgentType,
         pushPrimerOptions: UNAuthorizationOptions,
         configurationRepository: ConfigurationRepositoryType,
         notificationCenter: RemoteNotificationRequestable = UNUserNotificationCenter.current()) {

        self.pushPrimerOptions = pushPrimerOptions
        self.notificationCenter = notificationCenter
        super.init(campaignRepository: campaignRepository,
                   impressionService: impressionService,
                   eventMatcher: eventMatcher,
                   campaignTriggerAgent: campaignTriggerAgent,
                   configurationRepository: configurationRepository)
    }

    override func viewDidInitialize() {
        let messagePayload = campaign.data.messagePayload
        let viewModel = FullViewModel(image: associatedImage,
                                      backgroundColor: viewBackgroundColor,
                                      title: messagePayload.title,
                                      messageBody: messagePayload.messageBody,
                                      header: messagePayload.header,
                                      titleColor: UIColor(hexString: messagePayload.titleColor) ?? .black,
                                      headerColor: UIColor(hexString: messagePayload.headerColor) ?? .black,
                                      messageBodyColor: UIColor(hexString: messagePayload.messageBodyColor) ?? .black,
                                      isHTML: messagePayload.messageSettings.displaySettings.html,
                                      showOptOut: messagePayload.messageSettings.displaySettings.optOut,
                                      showButtons: !messagePayload.messageSettings.controlSettings.buttons.isEmpty,
                                      isDismissable: campaign.data.isCampaignDismissable)

        view?.setup(viewModel: viewModel)
    }

    func loadButtons() {
        let buttonList = campaign.data.messagePayload.messageSettings.controlSettings.buttons

        let supportedButtons = buttonList.prefix(2).filter {
            [.redirect, .deeplink, .close, .pushPrimer].contains($0.buttonBehavior.action)
        }

        var buttonsToAdd = [(ActionButton, ActionButtonViewModel)]()
        for (index, button) in supportedButtons.enumerated() {
            let backgroundColor = UIColor(hexString: button.buttonBackgroundColor) ?? .white
            buttonsToAdd.append((
                ActionButton(type: button.buttonBehavior.action,
                             impression: index == 0 ? ImpressionType.actionOne : ImpressionType.actionTwo,
                             uri: button.buttonBehavior.uri,
                             trigger: button.campaignTrigger),
                ActionButtonViewModel(text: button.buttonText,
                                      textColor: UIColor(hexString: button.buttonTextColor) ?? .black,
                                      backgroundColor: UIColor(hexString: button.buttonBackgroundColor) ?? .white,
                                      shouldDrawBorder: backgroundColor.isComparable(to: viewBackgroundColor))))
        }

        view?.addButtons(buttonsToAdd)
    }

    func didClickAction(sender: ActionButton) {
        logImpression(type: sender.impression)
        checkOptOutStatus()
        sendImpressions()

        if sender.type == .pushPrimer {
            pushPrimerAction()
        } else if let unwrappedUri = sender.uri {
            guard let uriToOpen = URL(string: unwrappedUri) else {
                if let view = view {
                    showURLError(view: view)
                }
                return
            }

            UIApplication.shared.open(uriToOpen, options: [:], completionHandler: { [view] success in
                if !success, let view = view {
                    self.showURLError(view: view)
                }
            })
        }

        // If the button came with a campaign trigger, log it.
        handleButtonTrigger(sender.trigger)

        view?.dismiss()
    }

    func didClickExitButton() {
        logImpression(type: .exit)
        checkOptOutStatus()
        sendImpressions()

        view?.dismiss()
    }

    // MARK: - Private

    private func checkOptOutStatus() {
        guard view?.isOptOutChecked == true else {
            return
        }

        logImpression(type: .optOut)
        optOutCampaign()
    }

    private func pushPrimerAction() {
        notificationCenter.getAuthorizationStatus { [self] authorizationStatus in
            // `self` becomes nil when the campaign window gets closed
            let willPopupAppear = authorizationStatus == .notDetermined

            self.notificationCenter.requestAuthorization(options: pushPrimerOptions) { [self] (granted, error) in
                if let error = error {
                    self.reportError(description: "PushPrimer: UNUserNotificationCenter requestAuthorization failed", data: error)
                } else if granted {
                    if willPopupAppear {
                        self.trackPushPrimerAction(didOptIn: true)
                    }
                    DispatchQueue.main.async(execute: self.notificationCenter.registerForRemoteNotifications)
                } else {
                    if willPopupAppear {
                        self.trackPushPrimerAction(didOptIn: false)
                    }
                    self.reportError(description: "PushPrimer: User has not granted authorization", data: nil)
                }
            }
        }
    }

    private func trackPushPrimerAction(didOptIn: Bool) {
        AnalyticsTracker.sendEventName(Constants.RAnalytics.pushPrimerEventName,
                                       dataObject: [Constants.RAnalytics.Keys.pushPermission: didOptIn ? 1 : 0,
                                                    Constants.RAnalytics.Keys.campaignID: campaign.id,
                                                    Constants.RAnalytics.Keys.subscriptionID: configurationRepository.getSubscriptionID() ?? "n/a"])
    }
}
