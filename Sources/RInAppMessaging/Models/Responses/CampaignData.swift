internal struct CampaignData: Codable, Hashable {
    let campaignId: String
    let maxImpressions: Int
    let type: CampaignDisplayType
    let triggers: [Trigger]?
    let isTest: Bool
    let infiniteImpressions: Bool
    let hasNoEndDate: Bool
    let isCampaignDismissable: Bool
    let messagePayload: MessagePayload

    var intervalBetweenDisplaysInMS: Int? {
        return messagePayload.messageSettings.displaySettings.delay
    }

    init(campaignId: String,
         maxImpressions: Int,
         type: CampaignDisplayType,
         triggers: [Trigger]?,
         isTest: Bool,
         infiniteImpressions: Bool,
         hasNoEndDate: Bool,
         isCampaignDismissable: Bool,
         messagePayload: MessagePayload) {
        
        self.campaignId = campaignId
        self.maxImpressions = maxImpressions
        self.type = type
        self.triggers = triggers
        self.isTest = isTest
        self.infiniteImpressions = infiniteImpressions
        self.hasNoEndDate = hasNoEndDate
        self.isCampaignDismissable = isCampaignDismissable
        self.messagePayload = messagePayload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        campaignId = try container.decode(String.self, forKey: .campaignId)
        maxImpressions = try container.decode(Int.self, forKey: .maxImpressions)
        type = try container.decode(CampaignDisplayType.self, forKey: .type)
        triggers = try container.decodeIfPresent([Trigger].self, forKey: .triggers)
        isTest = try container.decode(Bool.self, forKey: .isTest)
        infiniteImpressions = try container.decodeIfPresent(Bool.self, forKey: .infiniteImpressions) ?? false
        hasNoEndDate = try container.decodeIfPresent(Bool.self, forKey: .hasNoEndDate) ?? false
        isCampaignDismissable = try container.decodeIfPresent(Bool.self, forKey: .isCampaignDismissable) ?? true
        messagePayload = try container.decode(MessagePayload.self, forKey: .messagePayload)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(campaignId)
    }

    static func == (lhs: CampaignData, rhs: CampaignData) -> Bool {
        return lhs.campaignId == rhs.campaignId
    }
}
