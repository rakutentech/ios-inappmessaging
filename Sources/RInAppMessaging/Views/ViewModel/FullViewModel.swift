import UIKit

internal struct FullViewModel {
    let image: UIImage?
    let backgroundColor: UIColor
    let title: String
    let messageBody: String?
    let header: String?
    let titleColor: UIColor
    let headerColor: UIColor
    let messageBodyColor: UIColor
    let isHTML: Bool
    let showOptOut: Bool
    let showButtons: Bool
    let isDismissable: Bool
    let customJson: CustomJson?
    let carouselData: [CarouselData]?

    var hasText: Bool {
        [header, messageBody].contains { $0?.isEmpty == false }
    }
}
