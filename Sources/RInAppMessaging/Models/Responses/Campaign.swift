import Foundation

internal struct Campaign: Codable, Hashable {

    private enum CodingKeys: String, CodingKey {
        case data = "campaignData"
        case impressionsLeft // Cache coding only
        case isOptedOut // Cache coding only
    }

    let data: CampaignData
    let tooltipData: TooltipData?
    private(set) var impressionsLeft: Int
    private(set) var isOptedOut = false

    var id: String {
        data.campaignId
    }
    var isTooltip: Bool {
        data.messagePayload.title.lowercased().hasPrefix("[tooltip]") && tooltipData != nil
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
        data = decodedData
        tooltipData = Campaign.parseTooltipData(messagePayload: decodedData.messagePayload)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try container.encode(impressionsLeft, forKey: .impressionsLeft)
        try container.encode(isOptedOut, forKey: .isOptedOut)
    }

    init(data: CampaignData, asTooltip isTooltip: Bool = true) {
        self.data = data
        impressionsLeft = data.maxImpressions
        tooltipData = isTooltip ? Campaign.parseTooltipData(messagePayload: data.messagePayload) : nil
    }

    static func == (lhs: Campaign, rhs: Campaign) -> Bool {
        lhs.data == rhs.data
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

    private static func parseTooltipData(messagePayload: MessagePayload) -> TooltipData? {
        if let tooltipJsonData = messagePayload.messageBody?.data(using: .utf8),
           let tooltipBodyData = try? JSONDecoder().decode(TooltipBodyData.self, from: tooltipJsonData),
           let imageUrl = messagePayload.resource.imageUrl {
            return TooltipData(bodyData: tooltipBodyData,
                               backgroundColor: messagePayload.backgroundColor,
                               imageUrl: imageUrl)
        } else {
            return nil
        }
    }
}
