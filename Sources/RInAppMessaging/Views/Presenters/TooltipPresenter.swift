import UIKit

internal protocol TooltipPresenterType: ImpressionTrackable {
    var tooltip: Campaign? { get }
    var onDismiss: ((_ cancelled: Bool) -> Void)? { get set }

    func set(view: TooltipView, dataModel: Campaign, image: UIImage)
    func didTapExitButton()
    func didTapImage()
    func dismiss()
    func startAutoDisappearIfNeeded()
    func didRemoveFromSuperview()
}

internal class TooltipPresenter: TooltipPresenterType {

    var impressions: [Impression] = []
    var onDismiss: ((_ cancelled: Bool) -> Void)?
    private(set) var impressionService: ImpressionServiceType
    private(set) var tooltip: Campaign?
    private(set) var autoCloseTimer: Timer?
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

    func startAutoDisappearIfNeeded() {
        guard let autoCloseSeconds = tooltip?.tooltipData?.bodyData.autoCloseSeconds, autoCloseSeconds > 0 else {
            return
        }
        guard autoCloseTimer == nil else {
            return
        }

        let timer = Timer(fire: Date().addingTimeInterval(TimeInterval(autoCloseSeconds)), interval: 0, repeats: false, block: { [weak self] _ in
            self?.didTapExitButton()
        })

        autoCloseTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }

    func didTapImage() {
        guard let tooltipData = tooltip?.tooltipData,
              let uriToOpen = URL(string: tooltipData.bodyData.redirectURL ?? "") else {
                  return
              }

        autoCloseTimer?.invalidate()
        logImpression(type: .clickContent)
        sendImpressions()
        UIApplication.shared.open(uriToOpen)
        dismiss()
    }

    func didTapExitButton() {
        autoCloseTimer?.invalidate()
        logImpression(type: .exit)
        sendImpressions()
        dismiss()
    }

    func dismiss() {
        onDismiss?(false)
        view?.removeFromSuperview()
    }

    func didRemoveFromSuperview() {
        autoCloseTimer?.invalidate()
    }

    private func sendImpressions() {
        guard let tooltip = tooltip else {
            return
        }

        sendImpressions(for: tooltip)
        impressions.removeAll()
    }
}
