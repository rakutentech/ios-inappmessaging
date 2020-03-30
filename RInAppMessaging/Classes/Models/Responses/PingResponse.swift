internal struct PingResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case nextPingMilliseconds = "nextPingMillis"
        case currentPingMilliseconds = "currentPingMillis"
        case data
    }

    let nextPingMilliseconds: Int
    let currentPingMilliseconds: Int64
    let data: [Campaign]
}

internal struct Campaign: Decodable, Hashable {

    private enum CodingKeys: String, CodingKey {
        case data = "campaignData"
    }

    let data: CampaignData
    private(set) var impressionsLeft: Int
    private(set) var isOptedOut = false

    var id: String {
        return data.campaignId
    }
    var isOutdated: Bool {
        let endTimeMilliseconds = data.messagePayload.messageSettings.displaySettings.endTimeMilliseconds
        return endTimeMilliseconds < Date().millisecondsSince1970
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode(CampaignData.self, forKey: .data)
        impressionsLeft = data.maxImpressions
    }

    init(data: CampaignData) {
        self.data = data
        impressionsLeft = data.maxImpressions
    }

    static func == (lhs: Campaign, rhs: Campaign) -> Bool {
        return lhs.data == rhs.data
    }

    static func updatedCampaign(_ campaign: Campaign, withImpressionLeft impressionsLeft: Int) -> Campaign {
        var updatedCampaign = campaign
        updatedCampaign.impressionsLeft = impressionsLeft
        return updatedCampaign
    }

    static func updatedCampaign(_ campaign: Campaign, asOptedOut isOptedOut: Bool) -> Campaign {
        var updatedCampaign = campaign
        updatedCampaign.isOptedOut = isOptedOut
        return updatedCampaign
    }
}

internal struct CampaignData: Decodable, Hashable {
    let campaignId: String
    let maxImpressions: Int
    let type: Int
    let triggers: [Trigger]?
    let isTest: Bool
    let messagePayload: MessagePayload

    var intervalBetweenDisplaysInMS: Int? {
        return messagePayload.messageSettings.displaySettings.delay
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(campaignId)
    }

    static func == (lhs: CampaignData, rhs: CampaignData) -> Bool {
        return lhs.campaignId == rhs.campaignId
    }
}

internal struct Trigger: Decodable, Equatable {
    let type: CampaignTriggerType
    let eventType: EventType
    let eventName: String
    let attributes: [TriggerAttribute]
}

internal struct MessagePayload: Decodable {
    let title: String
    let messageBody: String?
    let messageLowerBody: String?
    let header: String?
    let titleColor: String
    let headerColor: String
    let messageBodyColor: String
    let backgroundColor: String
    let frameColor: String
    let resource: Resource
    let messageSettings: MessageSettings
}

internal struct Resource: Decodable {
    let assetsUrl: String?
    let imageUrl: String?
    let cropType: Int
}

internal struct MessageSettings: Decodable {
    let displaySettings: DisplaySettings
    let controlSettings: ControlSettings?
}

internal struct DisplaySettings: Decodable {
    private enum CodingKeys: String, CodingKey {
        case orientation
        case slideFrom
        case endTimeMilliseconds = "endTimeMillis"
        case textAlign
        case optOut
        case html
        case delay
    }

    let orientation: Int
    let slideFrom: SlideDirection?
    let endTimeMilliseconds: Int64
    let textAlign: Int
    let optOut: Bool
    let html: Bool?
    let delay: Int?
}

internal struct ControlSettings: Decodable {
    let buttons: [Button]?
    let content: Content?
}

internal struct Content: Decodable {
    let onClickBehavior: OnClickBehavior
    let campaignTrigger: Trigger?
}

internal struct OnClickBehavior: Decodable {
    let action: ActionType
    let uri: String?
}

internal struct Button: Decodable {
    let buttonText: String
    let buttonTextColor: String
    let buttonBackgroundColor: String
    let buttonBehavior: ButtonBehavior
    let campaignTrigger: Trigger?
}

internal struct ButtonBehavior: Decodable {
    let action: ActionType
    let uri: String?
}
