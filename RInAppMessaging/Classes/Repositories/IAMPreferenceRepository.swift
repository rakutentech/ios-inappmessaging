/// Repository to hold `IAMPreference`.
internal class IAMPreferenceRepository {
    private(set) var preference: UserInfoProvider?

    func setPreference(_ preference: UserInfoProvider?) {
        self.preference = preference
    }

    func canUpdateUserInfo(newUserInfo: UserInfoProvider?) -> Bool {
        func isEqual(_ lhs: UserInfoProvider, _ rhs: UserInfoProvider) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
        guard let newUserInfo = newUserInfo, let preference = preference else {
            return true
        }
        return !isEqual(preference, newUserInfo)
    }

    /// Method to convert the preferences object into
    /// an array that can be sent to the backend.
    /// - Returns: A list of IDs to send in request bodies.
    func getUserIdentifiers() -> [UserIdentifier] {

        // Check if preference is empty or not.
        guard let preference = preference else {
            return []
        }

        var userIdentifiers = [UserIdentifier]()

        if let rakutenId = preference.provideRakutenId {
            userIdentifiers.append(
                UserIdentifier(type: .rakutenId, identifier: rakutenId)
            )
        }

        if let userId = preference.provideUserId {
            userIdentifiers.append(
                UserIdentifier(type: .userId, identifier: userId)
            )
        }

        return userIdentifiers
    }

    /// Method to retrieve access token in preference object.
    /// - Returns: Access token as a string (Optional).
    func getAccessToken() -> String? {
        preference?.provideRaeToken
    }
}
