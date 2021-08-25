/// Builds `IAMPreference` object with provided user attributes
@objc public class IAMPreferenceBuilder: NSObject {

    private var preference: IAMPreference

    override public init() {
        self.preference = IAMPreference()
    }

    /// Sets auxiliary user identifier.
    /// - Parameter rakutenId: Auxiliary user identifier.
    @objc @discardableResult
    public func setRakutenId(_ rakutenId: String?) -> IAMPreferenceBuilder {
        self.preference.rakutenId = rakutenId
        return self
    }

    /// Sets primary user identifier (e.g. email)
    /// - Parameter userId: primary user identifier
    @objc @discardableResult
    public func setUserId(_ userId: String?) -> IAMPreferenceBuilder {
        self.preference.userId = userId
        return self
    }

    /// Sets access token for user tracking.
    /// - Parameter accessToken: An access token associated with userId.
    /// Note: When setting this value, userId MUST also be provided.
    /// - Tag: setAccessToken
    @objc @discardableResult
    public func setAccessToken(_ accessToken: String?) -> IAMPreferenceBuilder {
        self.preference.accessToken = accessToken
        return self
    }

    /// Sets identity tracking identifier.
    /// - Parameter idTrackingIdentifier: identity tracking identifier.
    /// Note: This value cannot be present along with `accessToken`.
    /// - Tag: setIDTrackingIdentifier
    @objc @discardableResult
    public func setIDTrackingIdentifier(_ idTrackingIdentifier: String?) -> IAMPreferenceBuilder {
        self.preference.idTrackingIdentifier = idTrackingIdentifier
        return self
    }

    /// Builds `IAMPreference` object with provided user data.
    /// Note: “Throws an assertion in debug mode when the preference id setter requirements are not met.
    /// See [setAccessToken](x-source-tag://setAccessToken) and [setIDTrackingIdentifier](x-source-tag://setIDTrackingIdentifier).
    /// - Returns: `IAMPreference` object to be used with `registerPreference()` method.
    @objc @discardableResult
    public func build() -> IAMPreference {
        if BundleInfo.applicationId?.starts(with: "jp.co.rakuten") == true, Bundle.tests == nil {
            checkAssertions()
        }
        return self.preference
    }

    func checkAssertions() {
        assert(!(preference.accessToken?.isEmpty == false && preference.userId?.isEmpty != false),
               "userId must be present and not empty when accessToken is specified")
        assert(!(preference.idTrackingIdentifier != nil && preference.accessToken != nil),
               "accessToken and idTrackingIdentifier shouldn't be used at the same time")
    }
}
