/// Struct for `InAppMessagingPreference` object that holds user related
/// identifiers such as User ID.
@objc public class IAMPreference: NSObject {
    internal enum Field {
        case rakutenId, userId, accessToken, idTrackingIdentifier
    }
    var rakutenId: String?
    var userId: String?
    var idTrackingIdentifier: String?
    var accessToken: String?

    internal func diff(_ otherPreference: IAMPreference?) -> [Field] {
        var diff = [Field]()
        if otherPreference?.rakutenId != rakutenId {
            diff.append(.rakutenId)
        }
        if otherPreference?.userId != userId {
            diff.append(.userId)
        }
        if otherPreference?.accessToken != accessToken {
            diff.append(.accessToken)
        }
        if otherPreference?.idTrackingIdentifier != idTrackingIdentifier {
            diff.append(.idTrackingIdentifier)
        }

        return diff
    }
}
