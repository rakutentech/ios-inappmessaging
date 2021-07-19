/**
 * Interface which client app should implement in order for InAppMessaging SDK to get information
 * when needed.
 */
@objc public protocol UserInfoProvider {

    /**
     * Only return ID token if user is logged in. Else return null.
     *
     * @return String of ID token.
     */
    func getIDToken() -> String?

    /**
     * Only return user ID used when logging if user is logged in in the current session.
     *
     * @return String of the user ID.
     */
    func getUserId() -> String?

    /**
     * Only return Rakuten ID used in the current session.
     *
     * @return String of the Rakuten ID.
     */
    func getRakutenId() -> String?
}

// MARK: - Private Properties
extension UserInfoProvider {
    /// Converted preferences object from
    /// an array that can be sent to the backend.
    /// - Returns: A list of IDs to send in request bodies.
    var userIdentifiers: [UserIdentifier] {
        var userIdentifiers = [UserIdentifier]()

        if let rakutenId = getRakutenId() {
            userIdentifiers.append(
                UserIdentifier(type: .rakutenId, identifier: rakutenId)
            )
        }

        if let userId = getUserId() {
            userIdentifiers.append(
                UserIdentifier(type: .userId, identifier: userId)
            )
        }

        return userIdentifiers
    }
}

// MARK: - UserInfoProvider equality
//public func == (lhs: UserInfoProvider?, rhs: UserInfoProvider?) -> Bool {
//    if let lhs = lhs {
//        if let rhs = rhs {
//            return lhs.getRakutenId() == rhs.getRakutenId() && lhs.getUserId() == rhs.getUserId()
//        }
//        return false
//    } else if let rhs = rhs {
//        if let lhs = lhs {
//            return lhs.getRakutenId() == rhs.getRakutenId() && lhs.getUserId() == rhs.getUserId()
//        }
//        return false
//    }
//    return true // nil == nil
//}
//
//public func != (lhs: UserInfoProvider?, rhs: UserInfoProvider?) -> Bool {
//    !(lhs == rhs)
//}

public func == (lhs: UserInfoProvider?, rhs: UserInfoProvider?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
      return l == r
    case (nil, nil):
      return true
    default:
      return false
    }
}

public func != (lhs: UserInfoProvider?, rhs: UserInfoProvider?) -> Bool {
    !(lhs == rhs)
}

public func == (lhs: UserInfoProvider, rhs: UserInfoProvider) -> Bool {
    lhs.getRakutenId() == rhs.getRakutenId() && lhs.getUserId() == rhs.getUserId()
}

public func != (lhs: UserInfoProvider, rhs: UserInfoProvider) -> Bool {
    !(lhs == rhs)
}
