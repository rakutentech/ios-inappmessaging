import UIKit

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

            Logger.debug("Error constructing a SlideUpView.")
            view?.dismiss()
            return
        }

        let viewModel = SlideUpViewModel(slideFromDirection: direction,
                                         backgroundColor: UIColor(hexString: messagePayload.backgroundColor) ?? .white,
                                         messageBody: messageBody,
                                         messageBodyColor: UIColor(hexString: messagePayload.messageBodyColor) ?? .black,
                                         isDismissable: campaign.data.isCampaignDismissable)
        view?.setup(viewModel: viewModel)
    }

    func didClickContent() {
        let campaignContent = campaign.data.messagePayload.messageSettings.controlSettings.content

        if [.redirect, .deeplink].contains(campaignContent?.onClickBehavior.action) {
            guard let uri = campaignContent?.onClickBehavior.uri,
                let uriToOpen = URL(string: uri) else {

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

        logImpression(type: .clickContent)
        sendImpressions()

        // If the button came with a campaign trigger, log it.
        handleButtonTrigger(campaignContent?.campaignTrigger)

        view?.dismiss()
    }

    func didClickExitButton() {
        logImpression(type: .exit)
        sendImpressions()

        view?.dismiss()
    }
}
