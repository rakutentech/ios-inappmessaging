import UIKit

internal protocol TooltipPresenterType: ImpressionTrackable {
    var tooltip: Campaign? { get }
    var onDismiss: (_ cancelled: Bool) -> Void { get set }

    func set(view: TooltipView, dataModel: Campaign, image: UIImage)
    func didTapExitButton()
    func didTapImage()
    func dismiss()
}

internal class TooltipPresenter: TooltipPresenterType {

    var impressions: [Impression] = []
    var onDismiss: (_ cancelled: Bool) -> Void = { _ in }
    private(set) var impressionService: ImpressionServiceType
    private(set) var tooltip: Campaign?
    private weak var view: TooltipView?

    init(impressionService: ImpressionServiceType) {
        self.impressionService = impressionService
    }

    func set(view: TooltipView, dataModel: Campaign, image: UIImage) {
        guard let tooltipData = dataModel.tooltipData else {
            return
        }
        tooltip = dataModel
        self.view = view
        view.setup(model: TooltipViewModel(position: tooltipData.bodyData.position,
                                           image: image,
                                           backgroundColor: UIColor(hexString: tooltipData.backgroundColor) ?? .white))
        logImpression(type: .impression)
    }

    func didTapImage() {
        guard let tooltipData = tooltip?.tooltipData,
              let uriToOpen = URL(string: tooltipData.bodyData.redirectURL ?? "") else {
                  return
              }

        logImpression(type: .clickContent)
        sendImpressions()
        UIApplication.shared.open(uriToOpen)
        dismiss()
    }

    func didTapExitButton() {
        logImpression(type: .exit)
        sendImpressions()
        dismiss()
    }

    func dismiss() {
        onDismiss(false)
        view?.removeFromSuperview()
    }

    private func sendImpressions() {
        guard let tooltip = tooltip else {
            return
        }

        sendImpressions(for: tooltip)
        impressions.removeAll()
    }
}
