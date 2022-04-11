import struct Foundation.Date

internal struct Campaign: Codable, Hashable {

    private enum CodingKeys: String, CodingKey {
        case data = "campaignData"
        case impressionsLeft // Cache coding only
        case isOptedOut // Cache coding only
    }

    let data: CampaignData
    private(set) var impressionsLeft: Int
    private(set) var isOptedOut = false

    var id: String {
        return data.campaignId
    }
    var isOutdated: Bool {
        guard !data.hasNoEndDate else {
            return false
        }
        let endTimeMilliseconds = data.messagePayload.messageSettings.displaySettings.endTimeMilliseconds
        return endTimeMilliseconds < Date().millisecondsSince1970
    }
    var contexts: [String] {
        data.messagePayload.title.components(separatedBy: "]").dropLast().map { substring in
            String(substring.drop(while: { $0 != "["}).dropFirst())
        }.filter { !$0.isEmpty }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedData = try container.decode(CampaignData.self, forKey: .data)
        var maxImpressions = decodedData.infiniteImpressions ? Int.max : decodedData.maxImpressions
        if decodedData.isTest {
            maxImpressions = 1
        }
        impressionsLeft = (try? container.decode(Int.self, forKey: .impressionsLeft)) ?? maxImpressions
        isOptedOut = (try? container.decode(Bool.self, forKey: .isOptedOut)) ?? false
        self.data = decodedData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try container.encode(impressionsLeft, forKey: .impressionsLeft)
        try container.encode(isOptedOut, forKey: .isOptedOut)
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
