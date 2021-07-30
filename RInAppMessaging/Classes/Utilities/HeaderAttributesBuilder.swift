struct HeaderAttributesBuilder {
    private let Keys = Constants.Request.Header.self
    private var addedHeaders: [HeaderAttribute] = []

    @discardableResult
    mutating func addDeviceID() -> Bool {
        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
            return false
        }
        addedHeaders.append(HeaderAttribute(key: Keys.deviceID, value: deviceId))
        return true
    }

    @discardableResult
    mutating func addSubscriptionID(bundleInfo: BundleInfo.Type) -> Bool {
        guard let subId = bundleInfo.inAppSubscriptionId, !subId.isEmpty else {
            return false
        }
        addedHeaders.append(HeaderAttribute(key: Keys.subscriptionID, value: subId))
        return true
    }

    @discardableResult
    mutating func addAccessToken(preferenceRepository: AccountRepositoryType) -> Bool {
        guard let authToken = preferenceRepository.userInfoProvider?.getAuthToken() else {
            return false
        }
        addedHeaders.append(HeaderAttribute(key: Keys.authorization, value: "OAuth2 \(authToken)"))
        return true
    }

    func build() -> [HeaderAttribute] {
        addedHeaders
    }
}
