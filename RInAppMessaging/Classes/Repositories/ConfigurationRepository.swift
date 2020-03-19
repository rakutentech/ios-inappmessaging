import Foundation

internal protocol ConfigurationRepositoryType: AnyObject {
    var defaultHttpSessionConfiguration: URLSessionConfiguration { get }

    func saveConfiguration(_ data: ConfigData)
    func getEndpoints() -> EndpointURL?
    func getIsEnabledStatus() -> Bool?
}

internal class ConfigurationRepository: ConfigurationRepositoryType {
    private var configuration: ConfigData?
    private(set) var defaultHttpSessionConfiguration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        return configuration
    }()

    func saveConfiguration(_ data: ConfigData) {
        configuration = data
    }

    func getEndpoints() -> EndpointURL? {
        return configuration?.endpoints
    }

    func getIsEnabledStatus() -> Bool? {
        return configuration?.enabled
    }
}
