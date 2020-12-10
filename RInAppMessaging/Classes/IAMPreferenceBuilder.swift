/// Builder for `IAMPreference`.
@objc public class IAMPreferenceBuilder: NSObject {

    private var preference: IAMPreference

    override public init() {
        self.preference = IAMPreference()
    }

    @objc @discardableResult
    public func setRakutenId(_ rakutenId: String?) -> IAMPreferenceBuilder {
        self.preference.rakutenId = rakutenId
        return self
    }

    @objc @discardableResult
    public func setUserId(_ userId: String?) -> IAMPreferenceBuilder {
        self.preference.userId = userId
        return self
    }

    @objc @discardableResult
    public func setAccessToken(_ accessToken: String?) -> IAMPreferenceBuilder {
        self.preference.accessToken = accessToken
        return self
    }

    @objc @discardableResult
    public func build() -> IAMPreference {
        if BundleInfo.applicationId?.starts(with: "jp.co.rakuten") == true, Bundle.tests == nil {
            assert(preference.accessToken == nil || preference.accessToken != nil && preference.userId != nil,
                   "userId must be present when accessToken is specified")
        }
        return self.preference
    }
}
