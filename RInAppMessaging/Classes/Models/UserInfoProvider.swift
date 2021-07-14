/**
 * Interface which client app should implement in order for InAppMessaging SDK to get information
 * when needed.
 */
@objc public protocol UserInfoProvider {

    /**
     * Only return RAE token if user is logged in. Else return null.
     *
     * @return String of RAE token.
     */
    var provideRaeToken: String? { get }

    /**
     * Only return user ID used when logging if user is logged in in the current session.
     *
     * @return String of the user ID.
     */
    var provideUserId: String? { get }

    /**
     * Only return Rakuten ID used in the current session.
     *
     * @return String of the Rakuten ID.
     */
    var provideRakutenId: String? { get }
}

extension UserInfoProvider {
    // swiftlint:disable:next legacy_hashing
    var hashValue: Int {
        (provideRakutenId ?? "").hashValue ^ (provideUserId ?? "").hashValue
    }
}
