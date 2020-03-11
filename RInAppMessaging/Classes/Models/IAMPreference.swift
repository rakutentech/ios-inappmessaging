/// Struct for `InAppMessagingPreference` object that holds user related
/// identifiers such as RakutenID, UserID, and RAE access token.
@objc public class IAMPreference: NSObject {
    var rakutenId: String?
    var userId: String?
    var accessToken: String?
}
