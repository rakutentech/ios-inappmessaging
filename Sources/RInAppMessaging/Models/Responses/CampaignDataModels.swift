internal struct MessagePayload: Codable {
    let title: String
    let messageBody: String?
    let header: String?
    let titleColor: String
    let headerColor: String
    let messageBodyColor: String
    let backgroundColor: String
    let frameColor: String
    let resource: Resource
    let messageSettings: MessageSettings
}

internal struct Resource: Codable {
    let imageUrl: String?
    let cropType: CampaignCropType
}

internal struct MessageSettings: Codable {
    let displaySettings: DisplaySettings
    let controlSettings: ControlSettings
}

internal struct DisplaySettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case orientation
        case slideFrom
        case endTimeMilliseconds = "endTimeMillis"
        case textAlign
        case optOut
        case html
        case delay
    }

    let orientation: CampaignOrientation
    let slideFrom: SlideDirection?
    let endTimeMilliseconds: Int64
    let textAlign: CampaignTextAlignType
    let optOut: Bool
    let html: Bool
    let delay: Int
}

internal struct ControlSettings: Codable {
    let buttons: [Button]
    let content: Content?
}

/// For slide-up campaigns
internal struct Content: Codable {
    let onClickBehavior: OnClickBehavior
    let campaignTrigger: Trigger?
}

internal struct OnClickBehavior: Codable {
    let action: ActionType
    let uri: String?
}

internal struct Button: Codable {
    let buttonText: String
    let buttonTextColor: String
    let buttonBackgroundColor: String
    let buttonBehavior: ButtonBehavior
    let campaignTrigger: Trigger?
}

internal struct ButtonBehavior: Codable {
    let action: ActionType
    let uri: String?
}

internal struct CustomJson: Codable {
    let pushPrimer: PrimerButton?
    let clickableImage: ClickableImage?
    let background: BackgroundColor?
    let carousel: Carousel?
    let modifyModal: ModifyModal?

    enum CodingKeys: String, CodingKey {
        case pushPrimer
        case clickableImage
        case background
        case carousel
        case modifyModal
    }

    init(pushPrimer: PrimerButton? = nil,
         clickableImage: ClickableImage? = nil,
         background: BackgroundColor? = nil,
         carousel: Carousel? = nil,
         modifyModal: ModifyModal? = nil) {
        self.pushPrimer = pushPrimer
        self.clickableImage = clickableImage
        self.background = background
        self.carousel = carousel
        self.modifyModal = modifyModal
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pushPrimer = try? container.decodeIfPresent(PrimerButton.self, forKey: .pushPrimer)
        clickableImage = try? container.decodeIfPresent(ClickableImage.self, forKey: .clickableImage)
        background = try? container.decodeIfPresent(BackgroundColor.self, forKey: .background)
        carousel = try? container.decodeIfPresent(Carousel.self, forKey: .carousel)
        modifyModal = try? container.decodeIfPresent(ModifyModal.self, forKey: .modifyModal)
    }
}

internal struct PrimerButton: Codable, Equatable {
    let button: Int?

    enum CodingKeys: String, CodingKey {
        case button
    }

    init(button: Int? = nil) {
        self.button = button
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.button = try? container.decodeIfPresent(Int.self, forKey: .button)
    }
}

internal struct ClickableImage: Codable, Equatable{
    let url: String?

    enum CodingKeys: String, CodingKey {
        case url
    }

    init(url: String? = nil) {
        self.url = url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try? container.decodeIfPresent(String.self, forKey: .url)
    }
}

internal struct BackgroundColor: Codable, Equatable {
    let opacity: Double?

    enum CodingKeys: String, CodingKey {
        case opacity
    }

    init(opacity: Double? = nil) {
        self.opacity = opacity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.opacity = try? container.decodeIfPresent(Double.self, forKey: .opacity)
    }
}

struct Carousel: Codable {
    let images: [String: ImageDetails]?

    enum CodingKeys: String, CodingKey {
        case images
    }

    init(images: [String: ImageDetails]?) {
        self.images = images
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        images = try container.decodeIfPresent([String: ImageDetails].self, forKey: .images)
    }
}

struct ImageDetails: Codable {
    let imgUrl: String?
    let link: String?
    let altText: String?

    enum CodingKeys: String, CodingKey {
        case imgUrl
        case link
        case altText
    }

    init(imgUrl: String?, link: String?, altText: String?) {
        self.imgUrl = imgUrl
        self.altText = altText
        self.link = link
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imgUrl = try container.decodeIfPresent(String.self, forKey: .imgUrl)
        link = try container.decodeIfPresent(String.self, forKey: .link)
        altText = try container.decodeIfPresent(String.self, forKey: .altText)
    }
}

struct ModifyModal: Codable {
    var size: Size?
    var position: Position?

    enum CodingKeys: String, CodingKey {
        case size
        case position
    }

    init(size: Size?, position: Position?) {
        self.size = size
        self.position = position
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        size = try container.decodeIfPresent(Size.self, forKey: .size)
        position = try container.decodeIfPresent(Position.self, forKey: .position)
    }
}

struct Size: Codable {
    var width: String?
    var height: String?

    enum CodingKeys: String, CodingKey {
        case width
        case height
    }

    init(width: String?, height: String?) {
        self.width = width
        self.height = height
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        width = try container.decodeIfPresent(String.self, forKey: .width)
        height = try container.decodeIfPresent(String.self, forKey: .height)
    }
}

struct Position: Codable {
    var verticalAlign: String?
    var horizontalAlign: String?

    enum CodingKeys: String, CodingKey {
        case verticalAlign
        case horizontalAlign
    }

    init(verticalAlign: String?, horizontalAlign: String?) {
        self.verticalAlign = verticalAlign
        self.horizontalAlign = horizontalAlign
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        verticalAlign = try container.decodeIfPresent(String.self, forKey: .verticalAlign)
        horizontalAlign = try container.decodeIfPresent(String.self, forKey: .horizontalAlign)
    }
}

enum VerticalAlignment: String, CaseIterable {
    case top, center, bottom
}

enum HorizontalAlignment: String, CaseIterable {
    case left, center, right
}
