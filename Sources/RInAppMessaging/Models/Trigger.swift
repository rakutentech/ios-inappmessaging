internal struct Trigger: Codable, Equatable {
    let type: CampaignTriggerType
    let eventType: EventType
    let eventName: String
    let attributes: [TriggerAttribute]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(CampaignTriggerType.self, forKey: CodingKeys.type)
        eventType = try container.decode(EventType.self, forKey: CodingKeys.eventType)
        eventName = try container.decode(String.self, forKey: CodingKeys.eventName).lowercased()
        attributes = try container.decode([TriggerAttribute].self, forKey: CodingKeys.attributes)
    }

    init(type: CampaignTriggerType, eventType: EventType, eventName: String, attributes: [TriggerAttribute]) {
        self.type = type
        self.eventType = eventType
        self.eventName = eventName.lowercased()
        self.attributes = attributes
    }
}

internal struct TriggerAttribute: Codable, Equatable {
    let name: String
    let value: String
    let type: AttributeType
    let `operator`: AttributeOperator

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: CodingKeys.name).lowercased()
        value = try container.decode(String.self, forKey: CodingKeys.value).lowercased()
        type = try container.decode(AttributeType.self, forKey: CodingKeys.type)
        `operator` = try container.decode(AttributeOperator.self, forKey: CodingKeys.operator)
    }

    init(name: String, value: String, type: AttributeType, `operator`: AttributeOperator) {
        self.name = name.lowercased()
        self.value = value.lowercased()
        self.type = type
        self.operator = `operator`
    }
}
