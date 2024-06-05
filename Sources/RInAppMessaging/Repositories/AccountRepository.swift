import class Foundation.Bundle

#if SWIFT_PACKAGE
import class RSDKUtilsMain.WeakWrapper
#else
import class RSDKUtils.WeakWrapper
#endif

/// Repository to hold `UserInfoProvider`.
internal protocol AccountRepositoryType {
    var userInfoProvider: UserInfoProvider? { get }

    /// Checks for user info changes and updates User data storage (cache).
    /// - Returns: true if there has been a change since last call
    @discardableResult func updateUserInfo() -> Bool
    func setPreference(_ preference: UserInfoProvider)
    func registerAccountUpdateObserver(_ observer: UserChangeObserver)
    func getUserIdentifiers() -> [UserIdentifier]
}

internal protocol UserChangeObserver: AnyObject {
    func userDidChangeOrLogout()
}

final class AccountRepository: AccountRepositoryType {
    let userDataCache: UserDataCacheable
    private(set) var userInfoProvider: UserInfoProvider?
    private var userInfoHash: String? // for comparing changes between users
    private var observers = [WeakWrapper<UserChangeObserver>]()

    init(userDataCache: UserDataCacheable) {
        self.userDataCache = userDataCache
    }

    func setPreference(_ preference: UserInfoProvider) {
        self.userInfoProvider = preference
    }

    func registerAccountUpdateObserver(_ observer: UserChangeObserver) {
        observers.append(WeakWrapper(value: observer))
    }

    @discardableResult
    func updateUserInfo() -> Bool {
        guard let userInfoProvider = userInfoProvider else {
            // No userInfoProvider object has been registered yet
            print("IAM Debug: \(Date()) No userInfoProvider object has been registered yet")
            return false
        }
        if BundleInfo.applicationId?.contains("rakuten") == true, !Environment.isUnitTestEnvironment {
            checkAssertions()
        }

        let newHash = userDataCache.userHash(from: userInfoProvider.userIdentifiers)
        print("IAM Debug: \(Date()) newHash \(String(newHash))")
        guard let currentHash = userInfoHash else {
            print("IAM Debug: \(Date()) updateUserInfo() called for the first time after registering `userInfoProvider`)")
            // updateUserInfo() has been called for the first time after registering `userInfoProvider`
            userInfoHash = newHash
            return true
        }

        let emptyHash = userDataCache.userHash(from: [])
        if currentHash != emptyHash && (newHash == emptyHash || currentHash != newHash) {
            observers.forEach { $0.value?.userDidChangeOrLogout() }
        }

        userInfoHash = newHash
        print("IAM Debug: \(Date()) userInfoHash \(String(describing: userInfoHash)) ")
        print("IAM Debug: \(Date()) \(currentHash != userInfoHash)")
        return currentHash != userInfoHash
    }

    func getUserIdentifiers() -> [UserIdentifier] {
        userInfoProvider?.userIdentifiers ?? []
    }

    // MARK: - Private

    // visible for testing
    func checkAssertions() {
        assert(!(userInfoProvider?.getAccessToken()?.isEmpty == false && userInfoProvider?.getUserID()?.isEmpty != false),
               "userId must be present and not empty when accessToken is specified")
        assert(!(userInfoProvider?.getIDTrackingIdentifier().isEmpty == false && userInfoProvider?.getAccessToken().isEmpty == false),
               "accessToken and idTrackingIdentifier shouldn't be used at the same time")
    }
}
