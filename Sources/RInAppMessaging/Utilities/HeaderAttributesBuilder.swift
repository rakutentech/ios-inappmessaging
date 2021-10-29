import class UIKit.UIDevice

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
    mutating func addAccessToken(accountRepository: AccountRepositoryType) -> Bool {
        guard let accessToken = accountRepository.userInfoProvider?.getAccessToken() else {
            return false
        }
        addedHeaders.append(HeaderAttribute(key: Keys.authorization, value: "OAuth2 \(accessToken)"))
        return true
    }

    func build() -> [HeaderAttribute] {
        addedHeaders
    }
}
