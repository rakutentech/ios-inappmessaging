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
    }
}

class AccountRepository: AccountRepositoryType {
    var userInfoProvider: UserInfoProvider?
    var userInfoHash: UserInfoProvider?

    // MARK: - AccountRepositoryType
    var idToken: String? {
        userInfoProvider?.getIDToken()
    }
    func getUserIdentifiers() -> [UserIdentifier] {
        updateUserInfo()
        return userInfoProvider?.userIdentifiers ?? []
    }

    @discardableResult
    func updateUserInfo() -> Bool {
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
