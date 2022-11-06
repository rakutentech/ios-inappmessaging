import Foundation

internal struct TooltipBodyData: Decodable, Hashable {

    enum Position: String, Decodable {
        case topLeft = "top-left"
        case topRight = "top-right"
        case topCenter = "top-center"
        case bottomLeft = "bottom-left"
        case bottomRight = "bottom-right"
        case bottomCenter = "bottom-center"
        case left
        case right
    }

    private enum CodingKeys: String, CodingKey {
        case uiElementIdentifier = "UIElement"
        case position
        case redirectURL
        case autoCloseSeconds = "auto-disappear"
    }

    let uiElementIdentifier: String
    let position: Position
    let redirectURL: String?
    let autoCloseSeconds: UInt?
}

internal struct TooltipData: Hashable {
    let bodyData: TooltipBodyData
    let backgroundColor: String
    let imageUrl: String
}
