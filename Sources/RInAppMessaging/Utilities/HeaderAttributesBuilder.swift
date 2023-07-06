import class UIKit.UIDevice

struct HeaderAttributesBuilder {
    private typealias Keys = Constants.Request.Header
    private var addedHeaders: [HeaderAttribute] = []

    @discardableResult
    mutating func addDeviceID() -> Bool {
        guard let deviceId = UIDevice.deviceID else {
            return false
        }
        addedHeaders.append(HeaderAttribute(key: Keys.deviceID, value: deviceId))
        return true
    }

    @discardableResult
    mutating func addSubscriptionID(configurationRepository: ConfigurationRepositoryType) -> Bool {
        guard let subId = configurationRepository.getSubscriptionID(), !subId.isEmpty else {
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
