internal struct DisplayPermissionResponse: Codable, Equatable {

    private enum CodingKeys: String, CodingKey {
        case display
        case performPing
        case creationTimeMilliseconds
    }

    let display: Bool
    let performPing: Bool
    let creationTimeMilliseconds: Int64 // Cache coding only

    // For unit tests
    init(display: Bool, performPing: Bool) {
        self.display = display
        self.performPing = performPing
        creationTimeMilliseconds = Date().millisecondsSince1970
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        display = try container.decode(Bool.self, forKey: .display)
        performPing = try container.decode(Bool.self, forKey: .performPing)
        creationTimeMilliseconds = (try? container.decode(Int64.self, forKey: .creationTimeMilliseconds)) ?? Date().millisecondsSince1970
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(display, forKey: .display)
        try container.encode(performPing, forKey: .performPing)
        try container.encode(creationTimeMilliseconds, forKey: .creationTimeMilliseconds)
    }
}
