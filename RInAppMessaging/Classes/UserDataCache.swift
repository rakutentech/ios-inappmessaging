internal protocol UserDataCacheable: AnyObject {
    func getUserData(identifiers: [UserIdentifier]) -> UserDataCacheContainer?
    func cacheCampaignData(_ data: [Campaign], userIdentifiers: [UserIdentifier])
    func cacheDisplayPermissionData(_ data: DisplayPermissionResponse, campaignID: String, userIdentifiers: [UserIdentifier])
    func deleteUserData(identifiers: [UserIdentifier])
}

internal struct UserDataCacheContainer: Codable, Equatable {
    fileprivate(set) var campaignData: [Campaign]?
    fileprivate var displayPermissionData: [String: DisplayPermissionResponse]

    init(campaignData: [Campaign]? = nil, displayPermissionData: [String: DisplayPermissionResponse] = [:]) {
        self.campaignData = campaignData
        self.displayPermissionData = displayPermissionData
    }

    func displayPermissionData(for campaign: Campaign) -> DisplayPermissionResponse? {
        return displayPermissionData[campaign.id]
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
                Logger.debug("UserDataCache decoding failed! \(error)")
                !Environment.isTestEnvironment ? assertionFailure() : ()
            }
        } else {
            cachedContainers = [:]
        }
    }

    func getUserData(identifiers: [UserIdentifier]) -> UserDataCacheContainer? {
        cachedContainers[userKey(from: identifiers)]
    }

    func cacheCampaignData(_ data: [Campaign], userIdentifiers: [UserIdentifier]) {
        let cacheKey = userKey(from: userIdentifiers)
        var currentData = cachedContainers[cacheKey] ?? UserDataCacheContainer()
        currentData.campaignData = data
        cachedContainers[cacheKey] = currentData
        saveData()
    }

    func cacheDisplayPermissionData(_ data: DisplayPermissionResponse, campaignID: String, userIdentifiers: [UserIdentifier]) {
        let cacheKey = userKey(from: userIdentifiers)
        var currentData = cachedContainers[cacheKey] ?? UserDataCacheContainer()
        currentData.displayPermissionData[campaignID] = data
        cachedContainers[cacheKey] = currentData
        saveData()
    }

    func deleteUserData(identifiers: [UserIdentifier]) {
        let cacheKey = userKey(from: identifiers)
        cachedContainers[cacheKey] = nil
        saveData()
    }

    private func saveData() {
        do {
            let encodedData = try JSONEncoder().encode(cachedContainers)
            userDefaults.set(encodedData, forKey: persistedDataKey)
        } catch {
            Logger.debug("UserDataCache encoding failed! \(error)")
            assertionFailure()
        }
    }

    private func userKey(from identifiers: [UserIdentifier]) -> String {
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
}
