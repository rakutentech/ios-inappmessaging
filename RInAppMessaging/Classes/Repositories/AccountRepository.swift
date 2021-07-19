/// Repository to hold `UserInfoProvider`.
protocol AccountRepositoryType {
    /// Access token from preference object.
    /// - Returns: Access token as a string (Optional).
    var idToken: String? { get }
    var userInfoProvider: UserInfoProvider? { get }
    var userInfoHash: UserInfoProvider? { get }
//    var hasLogoutOrUserChanged: Bool { get }

    func getUserIdentifiers() -> [UserIdentifier]

    /// Updates hash of userInfoProvider
    /// - Returns: true if there has been a change since last call
    @discardableResult func updateUserInfo() -> Bool
    func setPreference(_ preference: UserInfoProvider?)
}

extension AccountRepositoryType {
    var hasLogoutOrUserChanged: Bool {
        switch (userInfoHash, userInfoProvider) {
        case let (userInfoHash?, userInfoProvider?):
            return (userInfoProvider.userIdentifiers.isEmpty || userInfoHash != userInfoProvider)
                && !userInfoHash.userIdentifiers.isEmpty
        case (nil, nil):
            return false
        default: // one nil
            return true
        }
//        guard userInfoHash != nil && userInfoProvider != nil else {
//            return false
//        }
//
//        guard let userInfoHash = userInfoHash, let userInfoProvider = userInfoProvider else {
//            return true
//        }
//        return (userInfoProvider.userIdentifiers.isEmpty || userInfoHash != userInfoProvider)
//            && !userInfoHash.userIdentifiers.isEmpty
    }
}

class AccountRepository: AccountRepositoryType {
    var userInfoProvider: UserInfoProvider?
    var userInfoHash: UserInfoProvider?

    // MARK: - AccountRepositoryType
    var idToken: String? {
        userInfoProvider?.getIDToken()
    }

//    var hasLogoutOrUserChanged: Bool {
//        guard userInfoHash != nil, userInfoProvider != nil else {
//            return false
//        }
//        guard let userInfoHash = userInfoHash, let userInfoProvider = userInfoProvider else {
//            return true
//        }
//        return (userInfoProvider.userIdentifiers.isEmpty || userInfoHash != userInfoProvider)
//            && !userInfoHash.userIdentifiers.isEmpty
//    }

    func getUserIdentifiers() -> [UserIdentifier] {
        updateUserInfo()
        return userInfoProvider?.userIdentifiers ?? []
    }

    @discardableResult
    func updateUserInfo() -> Bool {
//        guard let curr = userInfoProvider, let userInfoHash = userInfoHash else {
//            return true
//        }
        let curr = userInfoProvider
        if userInfoHash != curr {
            self.userInfoHash = curr
            return true
        }

        return false
    }

    func setPreference(_ preference: UserInfoProvider?) {
        self.userInfoProvider = preference
    }
}
