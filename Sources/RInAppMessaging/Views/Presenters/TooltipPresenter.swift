import UIKit

internal protocol TooltipPresenterType: ImpressionTrackable {
    var tooltip: Campaign? { get set }
    var onClose: () -> Void { get set }

    func set(view: TooltipView, data: Campaign, image: UIImage)
    func didTapExitButton()
    func didTapImage()
}

internal class TooltipPresenter: TooltipPresenterType {

    private(set) var impressionService: ImpressionServiceType

    var tooltip: Campaign?
    var impressions: [Impression] = []
    var onClose: () -> Void = { }

    init(impressionService: ImpressionServiceType) {
        self.impressionService = impressionService
    }

    func set(view: TooltipView, data: Campaign, image: UIImage) {
        guard let tooltipData = data.tooltipData else {
            return
        }
        tooltip = data
        view.setup(model: TooltipViewModel(position: tooltipData.bodyData.position,
                                           image: image,
                                           backgroundColor: UIColor(hexString: tooltipData.backgroundColor) ?? .white))
        logImpression(type: .impression)
    }

    func sendImpressions() {
        guard let tooltip = tooltip else {
            return
        }

        sendImpressions(for: tooltip)
        impressions.removeAll()
    }

    func didTapImage() {
        guard let tooltipData = tooltip?.tooltipData,
              let uriToOpen = URL(string: tooltipData.bodyData.redirectURL ?? "") else {
                  return
              }

        logImpression(type: .clickContent)
        sendImpressions()
        UIApplication.shared.open(uriToOpen)
        onClose()
    }

    func didTapExitButton() {
        logImpression(type: .exit)
        sendImpressions()
        onClose()
    }
}
