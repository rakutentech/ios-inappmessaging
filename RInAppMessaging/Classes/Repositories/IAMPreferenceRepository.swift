/// Repository to hold `IAMPreference`.
internal class IAMPreferenceRepository {
    private(set) var preference: IAMPreference?

    func setPreference(_ preference: IAMPreference?) {
        self.preference = preference
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

        if let rakutenId = preference.rakutenId {
            userIdentifiers.append(
                UserIdentifier(type: .rakutenId, identifier: rakutenId)
            )
        }

        if let userId = preference.userId {
            userIdentifiers.append(
                UserIdentifier(type: .userId, identifier: userId)
            )
        }

        return userIdentifiers
    }

    /// Method to retrieve RAE access token in preference object.
    /// - Returns: Access token as a string (Optional).
    func getAccessToken() -> String? {
        return preference?.accessToken
    }
}
