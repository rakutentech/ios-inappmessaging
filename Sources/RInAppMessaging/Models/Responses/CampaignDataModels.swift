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
    
    enum CodingKeys: String, CodingKey {
        case pushPrimer
        case clickableImage
        case background
    }
    
    init(pushPrimer: PrimerButton? = nil, clickableImage: ClickableImage? = nil, background: BackgroundColor? = nil) {
        self.pushPrimer = pushPrimer
        self.clickableImage = clickableImage
        self.background = background
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pushPrimer = try? container.decodeIfPresent(PrimerButton.self, forKey: .pushPrimer)
        clickableImage = try? container.decodeIfPresent(ClickableImage.self, forKey: .clickableImage)
        background = try? container.decodeIfPresent(BackgroundColor.self, forKey: .background)
    }
}

internal struct PrimerButton: Codable {
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

internal struct ClickableImage: Codable {
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

internal struct BackgroundColor: Codable {
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
