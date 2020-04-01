import class UIKit.UIColor

internal protocol SlideUpViewPresenterType: BaseViewPresenterType {
    var view: SlideUpViewType? { get set }

    func didClickContent()
    func didClickExitButton()
}

internal class SlideUpViewPresenter: BaseViewPresenter, SlideUpViewPresenterType {

    weak var view: SlideUpViewType?

    override func viewDidInitialize() {
        let messagePayload = campaign.data.messagePayload

        guard let messageBody = messagePayload.messageBody,
            let direction = campaign.data.messagePayload.messageSettings.displaySettings.slideFrom else {

            CommonUtility.debugPrint("Error constructing a SlideUpView.")
            view?.dismiss()
            return
        }

        let viewModel = SlideUpViewModel(slideFromDirection: direction,
                                         backgroundColor: UIColor(fromHexString: messagePayload.backgroundColor) ?? .white,
                                         messageBody: messageBody,
                                         messageBodyColor: UIColor(fromHexString: messagePayload.messageBodyColor) ?? .black)
        view?.setup(viewModel: viewModel)
    }

    func didClickContent() {
        let campaignContent = campaign.data.messagePayload.messageSettings.controlSettings?.content

        if [.redirect, .deeplink].contains(campaignContent?.onClickBehavior.action) {
            guard let uri = campaignContent?.onClickBehavior.uri,
                let uriToOpen = URL(string: uri),
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

        view?.dismiss()

        logImpression(type: .clickContent)
        sendImpressions()

        // If the button came with a campaign trigger, log it.
        handleButtonTrigger(campaignContent?.campaignTrigger)
    }

    func didClickExitButton() {
        view?.dismiss()

        logImpression(type: .exit)
        sendImpressions()
    }
}
