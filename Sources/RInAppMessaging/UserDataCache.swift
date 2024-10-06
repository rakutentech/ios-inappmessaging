import Foundation

#if SWIFT_PACKAGE
import class RSDKUtilsMain.AtomicGetSet
#else
import class RSDKUtils.AtomicGetSet
#endif

internal protocol UserDataCacheable: AnyObject {
    func getUserData(identifiers: [UserIdentifier]) -> UserDataCacheContainer?
    func cacheCampaignData(_ data: [Campaign], userIdentifiers: [UserIdentifier])
    func cacheDisplayPermissionData(_ data: DisplayPermissionResponse, campaignID: String, userIdentifiers: [UserIdentifier])
    func deleteUserData(identifiers: [UserIdentifier])
    func userHash(from identifiers: [UserIdentifier]) -> String
}

internal struct UserDataCacheContainer: Codable, Equatable {
    fileprivate(set) var campaignData: [Campaign]?
    fileprivate var displayPermissionData: [String: DisplayPermissionResponse]

    init(campaignData: [Campaign]? = nil, displayPermissionData: [String: DisplayPermissionResponse] = [:]) {
        self.campaignData = campaignData
        self.displayPermissionData = displayPermissionData
    }

    func displayPermissionData(for campaign: Campaign) -> DisplayPermissionResponse? {
        displayPermissionData[campaign.id]
    }
}

internal class UserDataCache: UserDataCacheable {

    private typealias CacheContainers = [String: UserDataCacheContainer]

    private let userDefaults: UserDefaults
    @AtomicGetSet private var cachedContainers: CacheContainers
    private let persistedDataKey = "IAM_user_cache"

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults

        if let persistedData = userDefaults.object(forKey: persistedDataKey) as? Data {
            do {
                let decodedData = try JSONDecoder().decode(CacheContainers.self, from: persistedData)
                cachedContainers = decodedData
            } catch {
                cachedContainers = [:]
                IAMLogger.debug("UserDataCache decoding failed! \(error)")
                Environment.isUnitTestEnvironment ? () : assertionFailure()
            }
        } else {
            cachedContainers = [:]
        }
    }

    func getUserData(identifiers: [UserIdentifier]) -> UserDataCacheContainer? {
        cachedContainers[userHash(from: identifiers)]
    }

    func cacheCampaignData(_ data: [Campaign], userIdentifiers: [UserIdentifier]) {
        let cacheKey = userHash(from: userIdentifiers)
        var currentData = cachedContainers[cacheKey] ?? UserDataCacheContainer()
        currentData.campaignData = data
        cachedContainers[cacheKey] = currentData
        saveData()
    }

    func cacheDisplayPermissionData(_ data: DisplayPermissionResponse, campaignID: String, userIdentifiers: [UserIdentifier]) {
        let cacheKey = userHash(from: userIdentifiers)
        var currentData = cachedContainers[cacheKey] ?? UserDataCacheContainer()
        currentData.displayPermissionData[campaignID] = data
        cachedContainers[cacheKey] = currentData
        saveData()
    }

    func deleteUserData(identifiers: [UserIdentifier]) {
        let cacheKey = userHash(from: identifiers)
        cachedContainers[cacheKey] = nil
        saveData()
    }

    func userHash(from identifiers: [UserIdentifier]) -> String {
        var hasher = KeyHasher()
        identifiers.map({ $0.identifier }).sorted().forEach {
            hasher.combine($0)
        }
        hasher.encryptionMethod = .md5
        let salt = hasher.generateHash()
        hasher.encryptionMethod = .sha256
        hasher.salt = salt

        return hasher.generateHash()
    }

    private func saveData() {
        do {
            let encodedData = try JSONEncoder().encode(cachedContainers)
            userDefaults.set(encodedData, forKey: persistedDataKey)
        } catch {
            IAMLogger.debug("UserDataCache encoding failed! \(error)")
            assertionFailure()
        }
    }
}
