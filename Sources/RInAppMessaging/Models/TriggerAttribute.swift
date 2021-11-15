internal struct TriggerAttribute: Codable, Equatable {
    let name: String
    let value: String
    let type: AttributeType
    let `operator`: AttributeOperator
}
