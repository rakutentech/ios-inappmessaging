internal protocol UserDataCacheable: AnyObject {
    func getUserData(identifiers: [UserIdentifier]) -> UserDataCacheContainer?
    func cacheCampaignData(_ data: [Campaign], userIdentifiers: [UserIdentifier])
    func cacheDisplayPermissionData(_ data: DisplayPermissionResponse, campaignID: String, userIdentifiers: [UserIdentifier])
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

    private typealias CacheContainers = [Set<UserIdentifier>: UserDataCacheContainer]

    private let userDefaults: UserDefaults
    private var cachedContainers: CacheContainers
    private let persistedDataKey = "IAM_user_cache"
    private let isTestEnvironment = Bundle.tests != nil

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults

        if let persistedData = userDefaults.object(forKey: persistedDataKey) as? Data {
            do {
                let decodedData = try JSONDecoder().decode(CacheContainers.self, from: persistedData)
                cachedContainers = decodedData
            } catch {
                cachedContainers = [:]
                Logger.debug("UserDataCache decoding failed! \(error)")
                !isTestEnvironment ? assertionFailure() : ()
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

    private func saveData() {
        do {
            let encodedData = try JSONEncoder().encode(cachedContainers)
            userDefaults.set(encodedData, forKey: persistedDataKey)
        } catch {
            Logger.debug("UserDataCache encoding failed! \(error)")
            assertionFailure()
        }
    }

    private func userKey(from identifiers: [UserIdentifier]) -> Set<UserIdentifier> {
        Set<UserIdentifier>(identifiers)
    }
}
