internal protocol FullViewPresenterType: BaseViewPresenterType {
    var view: FullViewType? { get set }

    func loadButtons()
    func didClickAction(sender: ActionButton)
    func didClickExitButton()
    func loadResources()
}

internal class FullViewPresenter: BaseViewPresenter, FullViewPresenterType {
    weak var view: FullViewType?

    override func viewDidInitialize() {
        let messagePayload = campaign.data.messagePayload
        let viewModel = FullViewModel(image: associatedImage,
                                      backgroundColor: UIColor(fromHexString: messagePayload.backgroundColor) ?? .white,
                                      title: messagePayload.title,
                                      messageBody: messagePayload.messageBody,
                                      messageLowerBody: messagePayload.messageLowerBody,
                                      header: messagePayload.header,
                                      titleColor: UIColor(fromHexString: messagePayload.titleColor) ?? .black,
                                      headerColor: UIColor(fromHexString: messagePayload.headerColor) ?? .black,
                                      messageBodyColor: UIColor(fromHexString: messagePayload.messageBodyColor) ?? .black,
                                      isHTML: messagePayload.messageSettings.displaySettings.html == true,
                                      showOptOut: messagePayload.messageSettings.displaySettings.optOut,
                                      showButtons: messagePayload.messageSettings.controlSettings?.buttons?.isEmpty == false)

        view?.setup(viewModel: viewModel)
    }

    func loadResources() {
        _ = associatedImage
    }

    func loadButtons() {
        guard let buttonList = campaign.data.messagePayload.messageSettings.controlSettings?.buttons else {
            return
        }

        let supportedButtons = buttonList.prefix(2).filter {
            [.redirect, .deeplink, .close].contains($0.buttonBehavior.action)
        }

        var buttonsToAdd = [(ActionButton, ActionButtonViewModel)]()
        for (index, button) in supportedButtons.enumerated() {
            buttonsToAdd.append((
                ActionButton(impression: index == 0 ? ImpressionType.actionOne : ImpressionType.actionTwo,
                             uri: button.buttonBehavior.uri,
                             trigger: button.campaignTrigger),
                ActionButtonViewModel(text: button.buttonText,
                                      textColor: UIColor(fromHexString: button.buttonTextColor) ?? .black,
                                      backgroundColor: UIColor(fromHexString: button.buttonBackgroundColor) ?? .white)))

        }

        view?.addButtons(buttonsToAdd)
    }

    func didClickAction(sender: ActionButton) {
        view?.dismiss()

        logImpression(type: sender.impression)
        checkOptOutStatus()
        sendImpressions()

        if let unwrappedUri = sender.uri {
            guard let uriToOpen = URL(string: unwrappedUri),
                UIApplication.shared.canOpenURL(uriToOpen) else {

                view?.showAlert(title: "dialog_alert_invalidURI_title".localized,
                               message: "dialog_alert_invalidURI_message".localized,
                               style: .alert,
                               actions: [
                                UIAlertAction(title: "dialog_alert_invalidURI_close".localized,
                                              style: .default,
                                              handler: nil)
                ])
                return
            }

            UIApplication.shared.open(uriToOpen, options: [:], completionHandler: nil)
        }

        // If the button came with a campaign trigger, log it.
        handleButtonTrigger(sender.trigger)
    }

    func didClickExitButton() {
        view?.dismiss()

        logImpression(type: .exit)
        checkOptOutStatus()
        sendImpressions()
    }

    private func checkOptOutStatus() {
        guard view?.isOptOutChecked == true else {
            return
        }

        logImpression(type: .optOut)
        optOutCampaign()
    }
}
