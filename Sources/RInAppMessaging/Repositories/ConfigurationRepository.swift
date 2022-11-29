import Foundation

internal protocol ConfigurationRepositoryType: AnyObject {
    var defaultHttpSessionConfiguration: URLSessionConfiguration { get }
    var isTooltipFeatureEnabled: Bool { get }

    func saveRemoteConfiguration(_ data: ConfigEndpointData)
    func saveIAMModuleConfiguration(_ config: InAppMessagingModuleConfiguration)
    func getEndpoints() -> EndpointURL?
    func getRolloutPercentage() -> Int?
    func getSubscriptionID() -> String?
    func getConfigEndpointURL() -> String?
}

internal class ConfigurationRepository: ConfigurationRepositoryType {
    private var remoteConfiguration: ConfigEndpointData?
    private var iamModuleConfiguration: InAppMessagingModuleConfiguration?
    private(set) var defaultHttpSessionConfiguration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        return configuration
    }()
    var isTooltipFeatureEnabled: Bool {
        assert(iamModuleConfiguration != nil, "`iamModuleConfiguration` is not yet set. Possible race condition.")
        return iamModuleConfiguration?.isTooltipFeatureEnabled ?? false
    }

    func saveRemoteConfiguration(_ data: ConfigEndpointData) {
        remoteConfiguration = data
    }

    func saveIAMModuleConfiguration(_ config: InAppMessagingModuleConfiguration) {
        iamModuleConfiguration = config
    }

    func getEndpoints() -> EndpointURL? {
        remoteConfiguration?.endpoints
    }

    func getRolloutPercentage() -> Int? {
        remoteConfiguration?.rolloutPercentage
    }

    func getSubscriptionID() -> String? {
        iamModuleConfiguration?.subscriptionID
    }

    func getConfigEndpointURL() -> String? {
        iamModuleConfiguration?.configurationURL
    }
}
