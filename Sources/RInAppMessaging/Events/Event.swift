import Foundation

/// Event object that acts as the super class for other pre-defined Event classes.
/// Implements Codable in order for it to be encoded/decoded
/// as a data type and store/load from a property list.
@objc public class Event: NSObject, Codable {

    private enum CodingKeys: String, CodingKey {
        case type, timestamp, name
    }

    var type: EventType
    var timestamp: Int64
    var name: String

    var analyticsParameters: [String: Any] {
        return [:]
    }

    init(type: EventType, name: String, timestamp: Int64 = Date().millisecondsSince1970) {
        self.type = type
        self.timestamp = timestamp
        self.name = name.lowercased()
    }

    /// Used for custom atribute matching. Subclass will
    /// overwrite this if it uses CustomAttributes.
    func getAttributeMap() -> [String: CustomAttribute]? {
        return nil
    }

    // MARK: - Hashable (NSObject)

    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? Event else {
            return false
        }
        return self.type == object.type &&
            self.name == object.name
    }

    public override var hash: Int {
        return name.hashValue ^ type.hashValue
    }
}
