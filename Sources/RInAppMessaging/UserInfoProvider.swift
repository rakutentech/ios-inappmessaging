import Foundation

/// Interface which client app should implement in order for InAppMessaging SDK
/// to get user information when needed.
@objc public protocol UserInfoProvider {

    /// Access token for user tracking.
    ///
    /// Only return access token if user is logged in. Else return null.
    ///
    /// - Returns: String of access token.
    @objc func getAccessToken() -> String?

    /// Unique string to identify the user (like login ID or e-mail).
    ///
    /// Only return user ID if user is logged in in the current session.
    ///
    /// - Returns: String of the user ID.
    @objc func getUserID() -> String?

    /// Unique string to track the user.
    ///
    /// Only return Tracking Identifier used in the current session.
    /// - Note: This value cannot be present along with `accessToken`.
    ///
    /// - Returns: String of the Identity Tracking Identifier.
    @objc func getIDTrackingIdentifier() -> String?
}

// MARK: - Internal Properties
internal extension UserInfoProvider {
    /// Converted preferences object from
    /// an array that can be sent to the backend.
    /// - Returns: A list of IDs to send in request bodies.
    var userIdentifiers: [UserIdentifier] {
        var identifiers = [UserIdentifier]()

        if let idTrackingIdentifier = getIDTrackingIdentifier(), !idTrackingIdentifier.isEmpty {
            identifiers.append(
                UserIdentifier(type: .idTrackingIdentifier, identifier: idTrackingIdentifier)
            )
        }

        if let userID = getUserID(), !userID.isEmpty {
            identifiers.append(
                UserIdentifier(type: .userId, identifier: userID)
            )
        }

        return identifiers
    }
}

// MARK: - UserInfoProvider equality
@inlinable
func == (lhs: UserInfoProvider?, rhs: UserInfoProvider?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l == r
    case (nil, nil):
        return true
    default:
        return false
    }
}

@inlinable
func != (lhs: UserInfoProvider?, rhs: UserInfoProvider?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l != r
    case (nil, nil):
        return false
    default:
        return false
    }
}

@inlinable
func == (lhs: UserInfoProvider, rhs: UserInfoProvider) -> Bool {
    // null and empty values are treated the same
    // Access token does not define the user
    (lhs.getIDTrackingIdentifier() ?? "") == (rhs.getIDTrackingIdentifier() ?? "") &&
        (lhs.getUserID() ?? "") == (rhs.getUserID() ?? "")
}

@inlinable
func != (lhs: UserInfoProvider, rhs: UserInfoProvider) -> Bool {
    let equalsResult = lhs == rhs
    return !equalsResult
}
