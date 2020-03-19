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

        // Check if rakutenId is populated in preference.
        if let rakutenId = preference.rakutenId {
            userIdentifiers.append(
                UserIdentifier(type: Identification.rakutenId.rawValue, identifier: rakutenId)
            )
        }

        // Check if userId is populated in preference.
        if let userId = preference.userId {
            userIdentifiers.append(
                UserIdentifier(type: Identification.userId.rawValue, identifier: userId)
            )
        }

        return userIdentifiers
    }
}
