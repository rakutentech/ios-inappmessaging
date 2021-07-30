/// Repository to hold `UserInfoProvider`.
protocol AccountRepositoryType {
    var userInfoProvider: UserInfoProvider? { get }
    var userInfoHash: UserInfoProvider? { get }

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

final class AccountRepository: AccountRepositoryType {
    var userInfoProvider: UserInfoProvider?
    var userInfoHash: UserInfoProvider?

    // MARK: - AccountRepositoryType
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
